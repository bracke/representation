--  Representation.Typed_Codecs — the end-to-end typed codec (§33). It composes
--  the layer for one Ada type: decode drives the JSON document codec, validates
--  the resulting object against a field contract, then hands the validated
--  Document to a caller-supplied Read; encode builds a Document through a
--  caller-supplied Write and serializes it. The caller provides only the two
--  type-specific bindings (Read/Write) built from Objects/Values/Fields; all
--  grammar, limits, order-independence, duplicate/unknown handling, and
--  canonical output are handled by the layer below. Failures are values with a
--  category and (where available) a stable machine error id (Rule 4.6).
with Representation.Inputs;
with Representation.Outputs;
with Representation.Documents;
with Representation.Fields;
with Representation.Objects;
with Representation.Errors;
with Representation.Limits;
with Representation.JSON.Documents;
generic
   type Value_Type is private;

   --  Extract a Value_Type from a validated object node. Ok is False on any
   --  representation-level violation the contract could not express.
   with procedure Read
     (Doc   : Representation.Documents.Document;
      Obj   : Representation.Documents.Node_Ref;
      Value : out Value_Type;
      Ok    : out Boolean);

   --  Build the object node for Value in Doc (No_Node signals it could not be
   --  built, e.g. arena overflow).
   with procedure Write
     (Doc   : in out Representation.Documents.Document;
      Value : Value_Type;
      Obj   : out Representation.Documents.Node_Ref);

package Representation.Typed_Codecs is

   Max_Error_Id : constant := 64;

   type Decode_Report is record
      Ok        : Boolean := False;
      Category  : Representation.Errors.Error_Category :=
                    Representation.Errors.Ok;
      Offset    : Byte_Offset    := 0;
      Line      : Line_Number    := 1;
      Column    : Column_Number  := 1;
      Error_Len : Natural        := 0;
      Error_Buf : String (1 .. Max_Error_Id) := [others => ' '];
   end record;

   function Error_Id (R : Decode_Report) return String is
     (R.Error_Buf (1 .. R.Error_Len));

   type Encode_Report is record
      Ok       : Boolean := True;
      Category : Representation.Errors.Error_Category :=
                   Representation.Errors.Ok;
   end record;

   --  Decode a JSON value from Source into Value: parse -> validate against
   --  Contract with the given unknown-member Policy -> Read.
   procedure Decode
     (Source   : not null access Representation.Inputs.Source'Class;
      Contract : Representation.Fields.Field_Set;
      Value    : out Value_Type;
      Report   : out Decode_Report;
      Policy   : Representation.Objects.Unknown_Policy :=
        Representation.Objects.Reject;
      Node_Capacity  : Positive := 4096;
      Text_Capacity  : Positive := 65_536;
      Read_Capacity  : Positive := 4096;
      Value_Capacity : Positive := 65_536;
      Limits         : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits);

   --  Encode Value to Sink: Write into a Document -> serialize in Style.
   procedure Encode
     (Value  : Value_Type;
      Sink   : in out Representation.Outputs.Sink'Class;
      Report : out Encode_Report;
      Style  : Representation.JSON.Documents.Encoding :=
        Representation.JSON.Documents.Compact;
      Node_Capacity : Positive := 4096;
      Text_Capacity : Positive := 65_536);

end Representation.Typed_Codecs;
