--  Representation.Diagnostics — a bounded collection of individual issues
--  (§11). Typed object decoding may accumulate several independent semantic
--  issues where safe; the collection is bounded and reports its own
--  truncation explicitly. Each diagnostic identifies the failing structured
--  path (REP-INV-016) and a stable machine error id, and must not embed raw
--  sensitive values (REP-INV-017).
with Representation.Errors;
with Representation.Paths;
package Representation.Diagnostics
  with Preelaborate
is

   type Severity is (Info, Warning, Error);

   Max_Entries         : constant := 64;
   Max_Error_Id_Length : constant := 128;
   Max_Message_Length  : constant := 256;
   Max_Path_Length     : constant := 512;

   type Diagnostic is private;

   --  Build a diagnostic. Message must already be redaction-safe. Location
   --  fields are for textual codecs; pass zero when not applicable.
   function Make
     (Level    : Severity;
      Category : Representation.Errors.Error_Category;
      Error_Id : String;
      Path     : Representation.Paths.Path;
      Message  : String        := "";
      Offset   : Byte_Offset   := 0;
      Line     : Line_Number   := 0;
      Column   : Column_Number := 0) return Diagnostic;

   function Level (D : Diagnostic) return Severity;
   function Category
     (D : Diagnostic) return Representation.Errors.Error_Category;
   function Error_Identifier (D : Diagnostic) return String;
   function Path_Render (D : Diagnostic) return String;
   function Message (D : Diagnostic) return String;
   function Offset (D : Diagnostic) return Byte_Offset;
   function Line (D : Diagnostic) return Line_Number;
   function Column (D : Diagnostic) return Column_Number;

   --  A bounded, order-preserving set of diagnostics.
   type Diagnostic_Set is private;

   Empty_Set : constant Diagnostic_Set;

   procedure Clear (Set : out Diagnostic_Set);

   --  Append Item unless the set is at Capacity (a runtime bound from
   --  Representation.Limits, itself capped by Max_Entries): on overflow the
   --  item is dropped and the set is marked truncated.
   procedure Add
     (Set      : in out Diagnostic_Set;
      Item     : Diagnostic;
      Capacity : Field_Count := Field_Count (Max_Entries));

   function Count (Set : Diagnostic_Set) return Field_Count;
   function Truncated (Set : Diagnostic_Set) return Boolean;
   function Element (Set : Diagnostic_Set; Index : Positive) return Diagnostic
     with Pre => Index <= Natural (Count (Set));

private

   subtype Id_Length_Range   is Natural range 0 .. Max_Error_Id_Length;
   subtype Msg_Length_Range  is Natural range 0 .. Max_Message_Length;
   subtype Path_Length_Range is Natural range 0 .. Max_Path_Length;

   type Diagnostic is record
      Level      : Severity := Error;
      Category   : Representation.Errors.Error_Category :=
        Representation.Errors.Ok;
      Id_Length  : Id_Length_Range := 0;
      Id         : String (1 .. Max_Error_Id_Length) := [others => ' '];
      Msg_Length : Msg_Length_Range := 0;
      Msg        : String (1 .. Max_Message_Length) := [others => ' '];
      Pa_Length  : Path_Length_Range := 0;
      Pa         : String (1 .. Max_Path_Length) := [others => ' '];
      Offset     : Byte_Offset := 0;
      Line       : Line_Number := 0;
      Column     : Column_Number := 0;
   end record;

   subtype Entry_Count is Natural range 0 .. Max_Entries;
   type Entry_Array is array (1 .. Max_Entries) of Diagnostic;

   type Diagnostic_Set is record
      Count     : Entry_Count := 0;
      Truncated : Boolean     := False;
      Items     : Entry_Array;
   end record;

   Empty_Set : constant Diagnostic_Set :=
     (Count => 0, Truncated => False, Items => <>);

end Representation.Diagnostics;
