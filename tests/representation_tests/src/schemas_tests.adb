with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Errors;
with Representation.Fields;
with Representation.Objects;
with Representation.Schemas;
with Representation.Schemas.Compatibility;

package body Schemas_Tests is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Sch renames Representation.Schemas;
   package Cmp renames Representation.Schemas.Compatibility;
   use type Sch.Type_Kind;
   use type Cmp.Incompatibility;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   --  Build the person schema: id (integer, required), name (string, required),
   --  active (boolean, optional). Unknown policy configurable.
   procedure Build_Person
     (S : in out Sch.Schema; Policy : Obj.Unknown_Policy := Obj.Reject)
   is
      Added : Boolean;
   begin
      Sch.Start (S, Ids.To_Schema_Id ("person"), Policy);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("id"), FLD.Required),
                     Sch.Kind_Integer, Added);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("name"), FLD.Required),
                     Sch.Kind_String, Added);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("active"), FLD.Optional),
                     Sch.Kind_Boolean, Added);
      Sch.Finalize (S);
   end Build_Person;

   procedure Add_Person
     (Doc : in out DM.Document; O : DM.Node_Ref;
      Id_Text : String; Name_Node : DM.Node_Ref) is
   begin
      DM.Insert (Doc, O, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes (Id_Text)));
      DM.Insert (Doc, O, To_Bytes ("name"), Name_Node);
   end Add_Person;

   procedure Test_Build_And_Introspect (T : in out Fixture) is
      pragma Unreferenced (T);
      S : Sch.Schema (8);
   begin
      Build_Person (S);
      Assert (Ids.Image (Sch.Id (S)) = "person", "schema id");
      Assert (Sch.Field_Count (S) = 3, "three fields");
      Assert (Sch.Field_Type (S, 1) = Sch.Kind_Integer, "id is integer");
      Assert (Sch.Find (S, To_Bytes ("name")) = 2, "find by name");
      Assert (Sch.Find (S, To_Bytes ("missing")) = 0, "find absent");
      Assert (Sch.Is_Final (S), "finalized");
   end Test_Build_And_Introspect;

   procedure Test_Immutable_After_Finalize (T : in out Fixture) is
      pragma Unreferenced (T);
      S     : Sch.Schema (8);
      Added : Boolean;
   begin
      Build_Person (S);
      Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("extra"), FLD.Optional),
                     Sch.Kind_String, Added);
      Assert (not Added, "add refused after finalize (REP-INV-020)");
      Assert (Sch.Field_Count (S) = 3, "field count unchanged");
   end Test_Immutable_After_Finalize;

   procedure Test_Validate_Ok (T : in out Fixture) is
      pragma Unreferenced (T);
      S   : Sch.Schema (8);
      Doc : DM.Document (16, 128);
      O   : DM.Node_Ref;
      St  : Sch.Schema_Status;
   begin
      Build_Person (S);
      O := DM.Add_Object (Doc);
      Add_Person (Doc, O, "7", DM.Add_String (Doc, To_Bytes ("Ada")));
      DM.Insert (Doc, O, To_Bytes ("active"), DM.Add_Bool (Doc, True));
      Sch.Validate (Doc, O, S, St);
      Assert (St.Ok, "valid object accepted");
   end Test_Validate_Ok;

   procedure Test_Validate_Type_Mismatch (T : in out Fixture) is
      pragma Unreferenced (T);
      S   : Sch.Schema (8);
      Doc : DM.Document (16, 128);
      O   : DM.Node_Ref;
      St  : Sch.Schema_Status;
      use type Representation.Errors.Error_Category;
   begin
      Build_Person (S);
      O := DM.Add_Object (Doc);
      --  id declared integer, but a string is supplied.
      DM.Insert (Doc, O, To_Bytes ("id"), DM.Add_String (Doc, To_Bytes ("x")));
      DM.Insert (Doc, O, To_Bytes ("name"), DM.Add_String (Doc, To_Bytes ("Ada")));
      Sch.Validate (Doc, O, S, St);
      Assert (not St.Ok
              and then Sch.Error_Id (St)
                       = Representation.Errors.Field_Type_Mismatch
              and then St.Category = Representation.Errors.Representation_Constraint
              and then St.Field_Index = 1,
              "type mismatch on field 1");

      --  Non-object root is a structural error.
      Sch.Validate (Doc, DM.Add_Number (Doc, To_Bytes ("1")), S, St);
      Assert (not St.Ok and then St.Category
              = Representation.Errors.Structural_Error, "non-object root");
   end Test_Validate_Type_Mismatch;

   procedure Test_Validate_Missing_And_Unknown (T : in out Fixture) is
      pragma Unreferenced (T);
      S   : Sch.Schema (8);
      Doc : DM.Document (16, 128);
      O   : DM.Node_Ref;
      St  : Sch.Schema_Status;
   begin
      Build_Person (S);
      O := DM.Add_Object (Doc);
      DM.Insert (Doc, O, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("7")));
      Sch.Validate (Doc, O, S, St);
      Assert (not St.Ok
              and then Sch.Error_Id (St)
                       = Representation.Errors.Object_Missing_Field,
              "missing required name");

      --  Add name + an unknown member; default policy Reject.
      DM.Insert (Doc, O, To_Bytes ("name"), DM.Add_String (Doc, To_Bytes ("A")));
      DM.Insert (Doc, O, To_Bytes ("extra"), DM.Add_Bool (Doc, True));
      Sch.Validate (Doc, O, S, St);
      Assert (not St.Ok
              and then Sch.Error_Id (St)
                       = Representation.Errors.Object_Unknown_Field,
              "unknown member rejected");
   end Test_Validate_Missing_And_Unknown;

   procedure Test_Compatibility (T : in out Fixture) is
      pragma Unreferenced (T);
      Reader, Writer : Sch.Schema (8);
      Added          : Boolean;
   begin
      --  Identical schemas are compatible.
      Build_Person (Reader);
      Build_Person (Writer);
      Assert (Cmp.Is_Compatible (Cmp.Check_Read (Reader, Writer)),
              "identical schemas compatible");

      --  Writer lacks a reader-required field -> Missing_Required.
      declare
         W2 : Sch.Schema (8);
      begin
         Sch.Start (W2, Ids.To_Schema_Id ("person"), Obj.Reject);
         Sch.Add_Field (W2, FLD.Make (Ids.To_Field_Id ("id"), FLD.Required),
                        Sch.Kind_Integer, Added);
         Sch.Finalize (W2);   --  no "name"
         Assert (Cmp.Check_Read (Reader, W2).Reason = Cmp.Missing_Required,
                 "writer missing required name");
      end;

      --  Writer changes a field's type -> Type_Mismatch.
      declare
         W3 : Sch.Schema (8);
      begin
         Sch.Start (W3, Ids.To_Schema_Id ("person"), Obj.Reject);
         Sch.Add_Field (W3, FLD.Make (Ids.To_Field_Id ("id"), FLD.Required),
                        Sch.Kind_String, Added);   --  was integer
         Sch.Add_Field (W3, FLD.Make (Ids.To_Field_Id ("name"), FLD.Required),
                        Sch.Kind_String, Added);
         Sch.Finalize (W3);
         Assert (Cmp.Check_Read (Reader, W3).Reason = Cmp.Type_Mismatch,
                 "incompatible field type");
      end;

      --  Writer adds an extra field; a Reject reader rejects it, an Ignore
      --  reader tolerates it.
      declare
         W4 : Sch.Schema (8);
         R_Ignore : Sch.Schema (8);
      begin
         Sch.Start (W4, Ids.To_Schema_Id ("person"), Obj.Reject);
         Sch.Add_Field (W4, FLD.Make (Ids.To_Field_Id ("id"), FLD.Required),
                        Sch.Kind_Integer, Added);
         Sch.Add_Field (W4, FLD.Make (Ids.To_Field_Id ("name"), FLD.Required),
                        Sch.Kind_String, Added);
         Sch.Add_Field (W4, FLD.Make (Ids.To_Field_Id ("bonus"), FLD.Optional),
                        Sch.Kind_Number, Added);
         Sch.Finalize (W4);
         Assert (Cmp.Check_Read (Reader, W4).Reason = Cmp.Unknown_Rejected,
                 "reject reader rejects the writer's extra field");

         Build_Person (R_Ignore, Obj.Ignore);
         Assert (Cmp.Is_Compatible (Cmp.Check_Read (R_Ignore, W4)),
                 "ignore reader tolerates the extra field");
      end;
   end Test_Compatibility;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Schemas: build + introspect",
         Test_Build_And_Introspect'Access));
      Suite.Add_Test
        (Caller.Create ("Schemas: immutable after finalize",
         Test_Immutable_After_Finalize'Access));
      Suite.Add_Test
        (Caller.Create ("Schemas: validate ok", Test_Validate_Ok'Access));
      Suite.Add_Test
        (Caller.Create ("Schemas: type mismatch",
         Test_Validate_Type_Mismatch'Access));
      Suite.Add_Test
        (Caller.Create ("Schemas: missing + unknown",
         Test_Validate_Missing_And_Unknown'Access));
      Suite.Add_Test
        (Caller.Create ("Schemas: compatibility", Test_Compatibility'Access));
   end Add_Tests;

end Schemas_Tests;
