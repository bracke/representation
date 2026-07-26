--  Representation.Schemas — declarative object schemas (§34). A schema names an
--  object contract: an id, an ordered set of fields (each a Fields descriptor
--  plus a declared JSON type kind), and an unknown-member policy. A schema is
--  built incrementally, then Finalized; once final it is immutable — builder
--  operations are refused and only read-only introspection remains
--  (REP-INV-020). Validate checks a Document object against the schema:
--  presence, duplicate, and unknown-member rules (via Representation.Objects)
--  plus each present field's declared type. Failures are values (Rule 4.6).
with Representation.Documents;
with Representation.Identifiers;
with Representation.Fields;
with Representation.Objects;
with Representation.Errors;
package Representation.Schemas is

   --  The declared JSON type of a field's value.
   type Type_Kind is
     (Kind_Any,        --  any value (including null)
      Kind_Null,       --  must be null
      Kind_Boolean,
      Kind_Integer,    --  a number that is an exact integer
      Kind_Number,     --  any JSON number
      Kind_String,
      Kind_Enum,       --  a string (symbol validated by the field's codec)
      Kind_Reference,  --  a non-empty string reference
      Kind_Array,
      Kind_Object);

   type Schema (Capacity : Natural) is limited private;

   ---------------------------------------------------------------------------
   --  Building (only before Finalize).
   ---------------------------------------------------------------------------

   procedure Start
     (S       : in out Schema;
      Id      : Representation.Identifiers.Schema_Id;
      Unknown : Representation.Objects.Unknown_Policy :=
        Representation.Objects.Reject);

   --  Append a field. Added is False if the schema is final or full.
   procedure Add_Field
     (S     : in out Schema;
      Field : Representation.Fields.Field_Descriptor;
      Kind  : Type_Kind;
      Added : out Boolean);

   --  Seal the schema: no further fields may be added (REP-INV-020).
   procedure Finalize (S : in out Schema);
   function Is_Final (S : Schema) return Boolean;

   ---------------------------------------------------------------------------
   --  Introspection (read-only).
   ---------------------------------------------------------------------------

   function Id (S : Schema) return Representation.Identifiers.Schema_Id;
   function Unknown_Policy
     (S : Schema) return Representation.Objects.Unknown_Policy;
   function Field_Count (S : Schema) return Natural;
   function Field
     (S : Schema; Index : Positive)
      return Representation.Fields.Field_Descriptor
     with Pre => Index <= Field_Count (S);
   function Field_Type (S : Schema; Index : Positive) return Type_Kind
     with Pre => Index <= Field_Count (S);
   --  Index of the field whose name matches Name (0 if none).
   function Find (S : Schema; Name : Byte_Array) return Natural;

   --  Does the value node satisfy the declared type kind? (Kind_Any and a null
   --  value are handled per the Type_Kind rules.)
   function Accepts
     (Doc  : Representation.Documents.Document;
      N    : Representation.Documents.Node_Ref;
      Kind : Type_Kind) return Boolean;

   --  Human-readable name of a type kind, for diagnostics.
   function Kind_Name (Kind : Type_Kind) return String;

   ---------------------------------------------------------------------------
   --  Validation.
   ---------------------------------------------------------------------------

   type Schema_Status is record
      Ok          : Boolean := True;
      Category    : Representation.Errors.Error_Category :=
                      Representation.Errors.Ok;
      Field_Index : Natural := 0;   --  offending field on a type mismatch
      Error_Len   : Natural := 0;
      Error_Buf   : String (1 .. 64) := [others => ' '];
   end record;

   function Error_Id (Status : Schema_Status) return String is
     (Status.Error_Buf (1 .. Status.Error_Len));

   procedure Validate
     (Doc    : Representation.Documents.Document;
      Node   : Representation.Documents.Node_Ref;
      S      : Schema;
      Status : out Schema_Status);

private

   type Field_Entry is record
      Descr : Representation.Fields.Field_Descriptor;
      Kind  : Type_Kind := Kind_Any;
   end record;

   type Field_Array is array (Positive range <>) of Field_Entry;

   type Schema (Capacity : Natural) is limited record
      Ident   : Representation.Identifiers.Schema_Id;
      Policy  : Representation.Objects.Unknown_Policy :=
                  Representation.Objects.Reject;
      Fields  : Field_Array (1 .. Capacity);
      N       : Natural := 0;
      Final   : Boolean := False;
   end record;

end Representation.Schemas;
