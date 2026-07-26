--  Representation.JSON.Documents — the JSON document codec (§23): decode a JSON
--  byte stream into a bounded Representation.Documents.Document via the event
--  parser, and encode a Document back to JSON. Three encodings are offered:
--  Compact (no whitespace, members in insertion order, numbers verbatim),
--  Pretty (indented), and Canonical (no whitespace, object members sorted by
--  key bytes, numbers normalized to their exact canonical spelling). Canonical
--  output is deterministic and idempotent (REP-INV-001/008): equal values
--  encode to byte-identical output, and re-encoding canonical output is a
--  fixed point.
--
--  Everything is bounded and value-returning (Rule 4.6): decode reports failure
--  in a Decode_Result with a stable machine error id and location; encode
--  reports sink failure without raising.
with Representation.Inputs;
with Representation.Outputs;
with Representation.Limits;
with Representation.Errors;
with Representation.Documents;
package Representation.JSON.Documents is

   Max_Error_Id : constant := 64;

   type Decode_Result is record
      Ok        : Boolean := False;
      Root      : Representation.Documents.Node_Ref :=
                    Representation.Documents.No_Node;
      Category  : Representation.Errors.Error_Category :=
                    Representation.Errors.Ok;
      Offset    : Byte_Offset    := 0;
      Line      : Line_Number    := 1;
      Column    : Column_Number  := 1;
      Error_Len : Natural        := 0;
      Error_Buf : String (1 .. Max_Error_Id) := [others => ' '];
   end record;

   --  The stable machine error id of a failed decode ("" on success).
   function Error_Id (R : Decode_Result) return String is
     (R.Error_Buf (1 .. R.Error_Len));

   --  Parse one JSON value from Source into Doc (Cleared first). Read_Capacity
   --  sizes the read buffer; Value_Capacity must be at least the largest single
   --  string/number token (bounded by Limits.Max_String_Bytes). Duplicate
   --  member names within an object are rejected unless disabled.
   procedure Decode
     (Doc            : in out Representation.Documents.Document;
      Source         : not null access Representation.Inputs.Source'Class;
      Result         : out Decode_Result;
      Read_Capacity  : Positive := 4096;
      Value_Capacity : Positive := 65_536;
      Limits         : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits;
      Reject_Duplicate_Keys : Boolean := True);

   type Encoding is (Compact, Pretty, Canonical);

   type Encode_Result is record
      Ok       : Boolean := True;
      Category : Representation.Errors.Error_Category :=
                   Representation.Errors.Ok;
   end record;

   --  Serialize the subtree at Root of Doc to Sink in the requested Encoding.
   procedure Encode
     (Doc    : Representation.Documents.Document;
      Root   : Representation.Documents.Node_Ref;
      Sink   : in out Representation.Outputs.Sink'Class;
      Style  : Encoding := Compact;
      Result : out Encode_Result);

end Representation.JSON.Documents;
