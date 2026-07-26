--  Representation.Numbers — exact scalar numeric parsing (§7.1, REP-INV-003).
--  Integers are parsed with the strict JSON integer grammar and never silently
--  wrap: magnitude beyond the 64-bit range is reported as overflow. Integral
--  values are never routed through floating point. Marked SPARK_Mode as a
--  Phase 1 proof target.
with Interfaces;
package Representation.Numbers
  with Preelaborate, SPARK_Mode => On
is

   type Parse_Outcome is (Number_Ok, Number_Syntax, Number_Overflow);

   subtype Signed_Value   is Long_Long_Integer;
   subtype Unsigned_Value is Interfaces.Unsigned_64;

   --  Parse a JSON integer literal: -?(0|[1-9][0-9]*). Rejects a leading zero,
   --  an empty string, a sign other than a single leading '-', and any
   --  non-digit (so "1.5", "1e3", "+1", "01" are all Number_Syntax). Overflow
   --  beyond Signed_Value is Number_Overflow and never wraps.
   procedure Parse_Signed
     (Text    : String;
      Value   : out Signed_Value;
      Outcome : out Parse_Outcome);

   --  Parse an unsigned JSON integer literal: (0|[1-9][0-9]*), no sign.
   procedure Parse_Unsigned
     (Text    : String;
      Value   : out Unsigned_Value;
      Outcome : out Parse_Outcome);

   --  Locale-neutral minimal images (no leading blank).
   function Image (Value : Signed_Value) return String;
   function Image (Value : Unsigned_Value) return String;

end Representation.Numbers;
