--  schema_diagnostics — validate JSON against a schema and report every problem
--  as a path-stamped diagnostic. A field marked with a sensitive class has its
--  value redacted in messages (REP-INV-017), so credentials never leak into
--  error output.
with Ada.Text_IO; use Ada.Text_IO;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Errors;
with Representation.Fields;
with Representation.Objects;
with Representation.Schemas;
with Representation.Diagnostics;
with Representation.JSON.Typed;

procedure Schema_Diagnostics is

   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Sch renames Representation.Schemas;
   package D renames Representation.Diagnostics;
   package JT renames Representation.JSON.Typed;

   function Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

   S      : Sch.Schema (8);
   Added  : Boolean;
   Input  : aliased constant Byte_Array :=
     Bytes ("{ ""id"": ""oops"", ""secret"": 123 }");
   Src    : aliased Representation.Inputs.Array_Source (Input'Access);
   Doc    : Representation.Documents.Document (256, 4096);
   Root   : Representation.Documents.Node_Ref;
   Report : D.Diagnostic_Set;
   Ok     : Boolean;
begin
   --  id: integer, required; name: string, required; secret: string, required
   --  and Credential (its value is never echoed).
   Sch.Start (S, Ids.To_Schema_Id ("account"), Obj.Reject);
   Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("id"), FLD.Required),
                  Sch.Kind_Integer, Added);
   Sch.Add_Field (S, FLD.Make (Ids.To_Field_Id ("name"), FLD.Required),
                  Sch.Kind_String, Added);
   Sch.Add_Field
     (S,
      FLD.Make (Ids.To_Field_Id ("secret"), FLD.Required,
                Representation.Errors.Credential),
      Sch.Kind_String, Added);
   Sch.Finalize (S);

   D.Clear (Report);
   JT.Decode (Src'Access, S, Doc, Root, Report, Ok);

   Put_Line ("valid? " & Boolean'Image (Ok)
             & "  (" & D.Count (Report)'Image & " diagnostics)");
   for I in 1 .. Natural (D.Count (Report)) loop
      declare
         E : constant D.Diagnostic := D.Element (Report, I);
      begin
         Put_Line ("  " & D.Path_Render (E) & ": " & D.Message (E));
      end;
   end loop;
end Schema_Diagnostics;
