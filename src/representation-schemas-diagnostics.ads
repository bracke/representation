--  Representation.Schemas.Diagnostics — schema validation that reports every
--  issue, not just the first (§34/§11). Where the plain Schemas.Validate stops
--  at the first violation, this collects all of them into a bounded
--  Diagnostic_Set, each stamped with the failing field's structured path
--  (REP-INV-016). A field's value is only quoted in a message when the field's
--  sensitivity class permits it; sensitive values are redacted (REP-INV-017).
with Representation.Documents;
with Representation.Paths;
with Representation.Diagnostics;
with Representation.Errors;
package Representation.Schemas.Diagnostics is

   --  A diagnostics-safe rendering of a scalar/structural node's value: the
   --  literal text for public scalars (bounded and truncated), a placeholder
   --  for containers, and "<redacted>" whenever the class is redacted.
   function Redacted_Value
     (Doc   : Representation.Documents.Document;
      N     : Representation.Documents.Node_Ref;
      Class : Representation.Errors.Sensitivity_Class) return String;

   --  Validate Node against S, appending an Error diagnostic for each violation
   --  (wrong root, missing required field, field type mismatch, unknown member).
   --  Base is the path prefix of Node within a larger document. Ok is True iff
   --  no Error-level diagnostic was added.
   procedure Validate
     (Doc      : Representation.Documents.Document;
      Node     : Representation.Documents.Node_Ref;
      S        : Schema;
      Base     : Representation.Paths.Path;
      Into     : in out Representation.Diagnostics.Diagnostic_Set;
      Ok       : out Boolean;
      Capacity : Representation.Field_Count :=
        Representation.Field_Count (Representation.Diagnostics.Max_Entries));

end Representation.Schemas.Diagnostics;
