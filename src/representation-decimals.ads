--  Representation.Decimals — exact decimal numbers (§7.2, REP-INV-018). A
--  decimal is a bounded, normalized coefficient-and-exponent value:
--
--      value = (sign) * <significand as integer> * 10 ** exponent
--
--  The significand carries no leading or trailing zeros (zero is the single
--  digit "0" with exponent 0), so equal values have one representation and are
--  never silently rounded. Explicit digit and exponent limits reject
--  unsupported magnitude rather than approximating it. Integral and decimal
--  values are kept exact; nothing is routed through floating point.
package Representation.Decimals
  with Preelaborate
is

   Max_Significant_Digits : constant := 40;

   type Decimal is private;

   type Parse_Outcome is
     (Decimal_Ok,
      Decimal_Syntax,
      Decimal_Too_Many_Digits,
      Decimal_Exponent_Range);

   --  Parse a JSON number: -?(0|[1-9][0-9]*)(.[0-9]+)?([eE][+-]?[0-9]+)?.
   procedure Parse
     (Text    : String;
      Value   : out Decimal;
      Outcome : out Parse_Outcome);

   function Is_Zero (D : Decimal) return Boolean;
   function Is_Negative (D : Decimal) return Boolean;

   --  Normalized significant digits ("0" for zero; otherwise no leading or
   --  trailing zeros).
   function Significand (D : Decimal) return String;
   function Exponent (D : Decimal) return Exponent_Value;

   --  Deterministic, exact scientific image, e.g. "1.5E3", "-1.5E-2", "0".
   --  (The normative canonical spelling is defined in Phase 4/§23.)
   function Image (D : Decimal) return String;

   Zero : constant Decimal;

private

   type Sign_Type is (Nonneg, Neg);
   subtype Sig_Range is Natural range 0 .. Max_Significant_Digits;

   type Decimal is record
      Sign : Sign_Type := Nonneg;
      Len  : Sig_Range := 1;
      Coef : String (1 .. Max_Significant_Digits) := [others => '0'];
      Exp  : Exponent_Value := 0;
   end record;

   Zero : constant Decimal :=
     (Sign => Nonneg, Len => 1, Coef => [others => '0'], Exp => 0);

end Representation.Decimals;
