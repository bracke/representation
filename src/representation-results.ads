--  Representation.Results — the structured outcome of a whole operation (§11,
--  Rule 4.6). Ordinary malformed input, capacity exhaustion, unsupported
--  versions, and I/O failures are values of this type, never exceptions. An
--  outcome carries a category, a stable machine error identifier, and a
--  bounded human-readable message (which must never contain sensitive field
--  values — REP-INV-017). Fine-grained, multi-issue reporting lives in
--  Representation.Diagnostics; this type is the single pass/fail verdict.
with Representation.Errors;
use type Representation.Errors.Error_Category;
package Representation.Results
  with Preelaborate
is

   Max_Error_Id_Length : constant := 128;
   Max_Message_Length  : constant := 256;

   type Outcome is private;

   function Success return Outcome;

   function Failure
     (Category : Representation.Errors.Error_Category;
      Error_Id : String;
      Message  : String := "") return Outcome
     with Pre => Category /= Representation.Errors.Ok;

   function Is_Ok (O : Outcome) return Boolean;
   function Category (O : Outcome) return Representation.Errors.Error_Category;
   function Error_Identifier (O : Outcome) return String;
   function Message (O : Outcome) return String;

private

   subtype Id_Length_Range  is Natural range 0 .. Max_Error_Id_Length;
   subtype Msg_Length_Range is Natural range 0 .. Max_Message_Length;

   type Outcome is record
      Category : Representation.Errors.Error_Category :=
        Representation.Errors.Ok;
      Id_Length  : Id_Length_Range  := 0;
      Id         : String (1 .. Max_Error_Id_Length) := [others => ' '];
      Msg_Length : Msg_Length_Range := 0;
      Msg        : String (1 .. Max_Message_Length)  := [others => ' '];
   end record;

end Representation.Results;
