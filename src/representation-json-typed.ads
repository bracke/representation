--  Representation.JSON.Typed — the schema-typed JSON convenience layer (§37).
--  Decode parses JSON from a streaming source into a caller-owned Document and
--  validates it against a schema, accumulating every problem as a path-stamped,
--  redaction-safe diagnostic (REP-INV-016/017); a syntax failure yields one
--  diagnostic located by byte offset/line/column. Encode serializes a Document
--  subtree in the requested style (Compact/Pretty/Canonical). Both are
--  value-returning; neither raises on bad input (Rule 4.6).
with Representation.Inputs;
with Representation.Outputs;
with Representation.Documents;
with Representation.Schemas;
with Representation.Diagnostics;
with Representation.Limits;
with Representation.JSON.Documents;
package Representation.JSON.Typed is

   --  Decode Source into Doc (which is cleared first) and validate against
   --  Schema. Root is the decoded value (No_Node on a parse failure). Every
   --  parse or schema issue is appended to Report. Ok is True iff the JSON
   --  parsed and satisfied the schema.
   procedure Decode
     (Source         : not null access Representation.Inputs.Source'Class;
      Schema         : Representation.Schemas.Schema;
      Doc            : in out Representation.Documents.Document;
      Root           : out Representation.Documents.Node_Ref;
      Report         : in out Representation.Diagnostics.Diagnostic_Set;
      Ok             : out Boolean;
      Read_Capacity  : Positive := 4096;
      Value_Capacity : Positive := 65_536;
      Limits         : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits);

   subtype Encoding is Representation.JSON.Documents.Encoding;

   --  Serialize the subtree at Root in Style. Ok is False on sink failure or an
   --  incomplete tree.
   procedure Encode
     (Doc   : Representation.Documents.Document;
      Root  : Representation.Documents.Node_Ref;
      Sink  : in out Representation.Outputs.Sink'Class;
      Style : Encoding := Representation.JSON.Documents.Compact;
      Ok    : out Boolean);

end Representation.JSON.Typed;
