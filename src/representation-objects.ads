--  Representation.Objects — typed access to JSON object nodes against a field
--  contract (§28). Members are matched by name, so decoding is independent of
--  member order (REP-INV-006). Validation enforces required fields, rejects a
--  field supplied more than once under any of its names (REP-INV-002), and
--  applies an explicit unknown-member policy (REP-INV-011). The builder emits
--  each field's canonical name only, never an alias (REP-INV-009). Failures are
--  values with stable machine error ids, never exceptions (Rule 4.6).
with Representation.Documents;
with Representation.Fields;
with Representation.Errors;
package Representation.Objects is

   subtype Field_Set is Representation.Fields.Field_Set;

   --  What to do with a member that matches no declared field.
   type Unknown_Policy is
     (Reject,   --  a stray member fails validation
      Ignore,   --  a stray member is silently dropped
      Preserve); --  a stray member is kept (captured by the caller's extensions)

   Max_Error_Id : constant := 64;

   type Object_Status is record
      Ok        : Boolean := True;
      Category  : Representation.Errors.Error_Category :=
                    Representation.Errors.Ok;
      Error_Len : Natural := 0;
      Error_Buf : String (1 .. Max_Error_Id) := [others => ' '];
   end record;

   function Error_Id (S : Object_Status) return String is
     (S.Error_Buf (1 .. S.Error_Len));

   --  The value node of Field within object Obj, matched by canonical name then
   --  aliases, regardless of member position. No_Node if absent or Obj is not
   --  an object.
   function Lookup
     (Doc   : Representation.Documents.Document;
      Obj   : Representation.Documents.Node_Ref;
      Field : Representation.Fields.Field_Descriptor)
      return Representation.Documents.Node_Ref;

   --  Validate Obj against Contract: every Required field present (under any of
   --  its names); no field matched by more than one member; unknown members per
   --  Policy. Reports the first violation.
   procedure Validate
     (Doc      : Representation.Documents.Document;
      Obj      : Representation.Documents.Node_Ref;
      Contract : Field_Set;
      Policy   : Unknown_Policy;
      Status   : out Object_Status);

   --  Building. Members added via Put_Field carry the field's canonical name.
   function New_Object
     (Doc : in out Representation.Documents.Document)
      return Representation.Documents.Node_Ref;

   procedure Put_Field
     (Doc   : in out Representation.Documents.Document;
      Obj   : Representation.Documents.Node_Ref;
      Field : Representation.Fields.Field_Descriptor;
      Value : Representation.Documents.Node_Ref);

end Representation.Objects;
