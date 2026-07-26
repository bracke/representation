--  Representation.Schemas.Compatibility — schema evolution checks (§34). Given
--  two schemas, decide whether a consumer using the Reader schema can safely
--  read data produced under the Writer schema. The check is directional and
--  conservative: it fails closed on anything that could surprise the reader — a
--  required field the writer does not guarantee, a field whose declared type
--  changed incompatibly, or (when the reader rejects unknowns) a field the
--  writer emits that the reader does not declare. The result is a value, never
--  an exception (Rule 4.6).
package Representation.Schemas.Compatibility is

   type Incompatibility is
     (Compatible,
      Missing_Required,   --  reader requires a field the writer never guarantees
      Type_Mismatch,      --  a shared field's declared type is incompatible
      Unknown_Rejected);  --  reader rejects unknowns; writer emits an extra field

   type Result is record
      Reason      : Incompatibility := Compatible;
      --  1-based index into the reader schema (Missing_Required / Type_Mismatch)
      --  or the writer schema (Unknown_Rejected); 0 when compatible.
      Field_Index : Natural := 0;
   end record;

   function Is_Compatible (R : Result) return Boolean is
     (R.Reason = Compatible);

   --  Can a Reader-schema consumer read data produced under Writer?
   function Check_Read (Reader : Schema; Writer : Schema) return Result;

end Representation.Schemas.Compatibility;
