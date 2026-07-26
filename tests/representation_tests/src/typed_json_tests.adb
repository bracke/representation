with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Errors;
with Representation.Fields;
with Representation.Objects;
with Representation.Paths;
with Representation.Diagnostics;
with Representation.Schemas;
with Representation.Schemas.Diagnostics;
with Representation.JSON.Documents;
with Representation.JSON.Typed;

package body Typed_JSON_Tests is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package P renames Representation.Paths;
   package D renames Representation.Diagnostics;
   package Sch renames Representation.Schemas;
   package SD renames Representation.Schemas.Diagnostics;
   package JT renames Representation.JSON.Typed;
   package Errs renames Representation.Errors;
   use type DM.Node_Ref;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function Contains (H, N : String) return Boolean is
   begin
      if N'Length = 0 then
         return True;
      end if;
      for I in H'First .. H'Last - N'Length + 1 loop
         if H (I .. I + N'Length - 1) = N then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   --  Schema: id (integer, required), name (string, required), age (integer,
   --  optional), secret (string, required, Credential). Rejects unknowns.
   procedure Build_Schema (S : in out Sch.Schema) is
      Added : Boolean;
   begin
      Sch.Start (S, Ids.To_Schema_Id ("account"), Obj.Reject);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("id"), FLD.Required),
                     Sch.Kind_Integer, Added);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("name"), FLD.Required),
                     Sch.Kind_String, Added);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("age"), FLD.Optional),
                     Sch.Kind_Integer, Added);
      Sch.Add_Field
        (S, FLD.Make (Ids.To_Field_Id ("secret"), FLD.Required, Errs.Credential),
         Sch.Kind_String, Added);
      Sch.Finalize (S);
   end Build_Schema;

   procedure Test_Redaction (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : DM.Document (8, 64);
      Str : constant DM.Node_Ref := DM.Add_String (Doc, To_Bytes ("topsecret"));
   begin
      Assert (SD.Redacted_Value (Doc, Str, Errs.Public) = """topsecret""",
              "public value shown");
      Assert (SD.Redacted_Value (Doc, Str, Errs.Credential) = "<redacted>",
              "credential value redacted (REP-INV-017)");
      Assert (SD.Redacted_Value (Doc, Str, Errs.Secret) = "<redacted>",
              "secret value redacted");
   end Test_Redaction;

   procedure Test_Multi_Issue_Paths (T : in out Fixture) is
      pragma Unreferenced (T);
      S      : Sch.Schema (8);
      Doc    : DM.Document (16, 256);
      O      : DM.Node_Ref;
      Report : D.Diagnostic_Set;
      Ok     : Boolean;
   begin
      Build_Schema (S);
      D.Clear (Report);
      --  Missing id + secret; name is a number (wrong type); unknown member x.
      O := DM.Add_Object (Doc);
      DM.Insert (Doc, O, To_Bytes ("name"), DM.Add_Number (Doc, To_Bytes ("5")));
      DM.Insert (Doc, O, To_Bytes ("x"), DM.Add_Bool (Doc, True));

      SD.Validate (Doc, O, S, P.Empty_Path, Report, Ok);
      Assert (not Ok, "invalid object");
      --  id missing, name type mismatch, secret missing, x unknown = 4 issues.
      Assert (D.Count (Report) = 4, "all issues collected, not just the first");

      declare
         Saw_Id_Path   : Boolean := False;
         Saw_Name_Type : Boolean := False;
      begin
         for I in 1 .. Natural (D.Count (Report)) loop
            declare
               E : constant D.Diagnostic := D.Element (Report, I);
            begin
               if D.Path_Render (E) = "$.id"
                 and then D.Error_Identifier (E)
                          = Errs.Object_Missing_Field
               then
                  Saw_Id_Path := True;
               end if;
               if D.Path_Render (E) = "$.name"
                 and then Contains (D.Message (E), "expected string")
               then
                  Saw_Name_Type := True;
               end if;
            end;
         end loop;
         Assert (Saw_Id_Path, "missing id stamped with path $.id (REP-INV-016)");
         Assert (Saw_Name_Type, "name mismatch stamped with path $.name");
      end;
   end Test_Multi_Issue_Paths;

   procedure Test_Decode_Valid (T : in out Fixture) is
      pragma Unreferenced (T);
      S      : Sch.Schema (8);
      Data   : aliased constant Byte_Array :=
        To_Bytes ("{""id"":1,""name"":""a"",""secret"":""s""}");
      Src    : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc    : DM.Document (32, 256);
      Root   : DM.Node_Ref;
      Report : D.Diagnostic_Set;
      Ok     : Boolean;
   begin
      Build_Schema (S);
      D.Clear (Report);
      JT.Decode (Src'Access, S, Doc, Root, Report, Ok,
                 Read_Capacity => 32, Value_Capacity => 128);
      Assert (Ok and then D.Count (Report) = 0, "valid input, no diagnostics");
      Assert (Root /= DM.No_Node, "root present");
   end Test_Decode_Valid;

   procedure Test_Decode_Syntax (T : in out Fixture) is
      pragma Unreferenced (T);
      S      : Sch.Schema (8);
      Data   : aliased constant Byte_Array := To_Bytes ("{""id"":");
      Src    : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc    : DM.Document (32, 256);
      Root   : DM.Node_Ref;
      Report : D.Diagnostic_Set;
      Ok     : Boolean;
      use type Representation.Errors.Error_Category;
   begin
      Build_Schema (S);
      D.Clear (Report);
      JT.Decode (Src'Access, S, Doc, Root, Report, Ok,
                 Read_Capacity => 32, Value_Capacity => 128);
      Assert (not Ok and then D.Count (Report) = 1, "one syntax diagnostic");
      declare
         E : constant D.Diagnostic := D.Element (Report, 1);
      begin
         Assert (D.Category (E) = Representation.Errors.Syntax_Error,
                 "syntax category");
         Assert (D.Line (E) >= 1, "located");
      end;
   end Test_Decode_Syntax;

   procedure Test_Decode_Schema_Invalid (T : in out Fixture) is
      pragma Unreferenced (T);
      S      : Sch.Schema (8);
      Data   : aliased constant Byte_Array := To_Bytes ("{""id"":""x""}");
      Src    : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc    : DM.Document (32, 256);
      Root   : DM.Node_Ref;
      Report : D.Diagnostic_Set;
      Ok     : Boolean;
   begin
      Build_Schema (S);
      D.Clear (Report);
      JT.Decode (Src'Access, S, Doc, Root, Report, Ok,
                 Read_Capacity => 32, Value_Capacity => 128);
      --  Parses, but id is wrong type and name + secret are missing.
      Assert (not Ok and then D.Count (Report) >= 2,
              "schema issues reported after a clean parse");
   end Test_Decode_Schema_Invalid;

   procedure Test_Encode (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (16, 128);
      O    : DM.Node_Ref;
      Buf  : aliased Representation.Buffers.Buffer (128);
      Snk  : Representation.Buffers.Buffer_Sink (Buf'Access);
      Ok   : Boolean;
   begin
      O := DM.Add_Object (Doc);
      DM.Insert (Doc, O, To_Bytes ("b"), DM.Add_Number (Doc, To_Bytes ("2")));
      DM.Insert (Doc, O, To_Bytes ("a"), DM.Add_Number (Doc, To_Bytes ("1")));
      JT.Encode (Doc, O, Snk, Representation.JSON.Documents.Canonical, Ok);
      Assert (Ok, "encode ok");
      declare
         Out_Bytes : constant Byte_Array :=
           Representation.Buffers.To_Byte_Array (Buf);
         Out_Str   : String (1 .. Out_Bytes'Length);
      begin
         for I in Out_Bytes'Range loop
            Out_Str (I - Out_Bytes'First + 1) :=
              Character'Val (Natural (Out_Bytes (I)));
         end loop;
         Assert (Out_Str = "{""a"":1,""b"":2}", "canonical typed encode");
      end;
   end Test_Encode;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Typed JSON: redaction", Test_Redaction'Access));
      Suite.Add_Test
        (Caller.Create ("Typed JSON: multi-issue paths",
         Test_Multi_Issue_Paths'Access));
      Suite.Add_Test
        (Caller.Create ("Typed JSON: decode valid", Test_Decode_Valid'Access));
      Suite.Add_Test
        (Caller.Create ("Typed JSON: decode syntax", Test_Decode_Syntax'Access));
      Suite.Add_Test
        (Caller.Create ("Typed JSON: decode schema-invalid",
         Test_Decode_Schema_Invalid'Access));
      Suite.Add_Test
        (Caller.Create ("Typed JSON: encode", Test_Encode'Access));
   end Add_Tests;

end Typed_JSON_Tests;
