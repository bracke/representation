--  representation — strongly typed, transport-independent external
--  representation contracts and codecs.
--
--  The root package holds only the crate-wide strong scalar vocabulary
--  (Rule 4.7): conceptually distinct quantities get distinct types, so byte
--  counts, element counts, depths, offsets, and version-like numbers can
--  never be silently interchanged. No behaviour lives here; the root must
--  stay a small vocabulary, not a dependency hub.
package Representation
  with Pure
is

   --  Byte-oriented quantities: input sizes, offsets, buffer capacities.
   type Byte_Count  is range 0 .. 2 ** 48;
   type Byte_Offset is range 0 .. 2 ** 48;

   --  Textual and structural counts.
   type Scalar_Count  is range 0 .. 2 ** 32;   --  Unicode scalar values
   type Element_Count is range 0 .. 2 ** 32;   --  array elements
   type Field_Count   is range 0 .. 2 ** 24;   --  object members / extensions
   type Value_Count   is range 0 .. 2 ** 32;   --  total values in a document
   type Depth_Count   is range 0 .. 4_096;     --  structural nesting depth
   type Path_Depth    is range 0 .. 4_096;     --  path segment depth

   --  Zero-based external index into a representation array.
   type Array_Index is range 0 .. 2 ** 32 - 1;

   --  Exact-decimal budgets.
   type Digit_Count    is range 0 .. 4_096;
   type Exponent_Value is range -(2 ** 20) .. 2 ** 20;

   --  Source location counters for textual codecs. One-based; zero means
   --  "unknown / not applicable".
   type Line_Number   is range 0 .. 2 ** 32;
   type Column_Number is range 0 .. 2 ** 32;

   --  Raw octets. The wire is bytes; byte-level work stays confined to the I/O
   --  and codec internals, and domain records are never transmitted raw
   --  (Rule 4.8, §3 non-goals).
   type Byte is mod 2 ** 8;
   type Byte_Array is array (Positive range <>) of Byte;

   --  Crate identity, for diagnostics and release reporting.
   Library_Name    : constant String := "representation";
   Library_Version : constant String := "0.1.0-dev";

end Representation;
