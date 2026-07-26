with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;          use Representation;
with Representation.Decimals;

package body Decimals_Tests is

   package D renames Representation.Decimals;
   use type D.Parse_Outcome;

   function Ok
     (Text : String;
      Sig  : String;
      Exp  : Exponent_Value;
      Neg  : Boolean) return Boolean
   is
      V : D.Decimal;
      O : D.Parse_Outcome;
   begin
      D.Parse (Text, V, O);
      return O = D.Decimal_Ok
        and then D.Significand (V) = Sig
        and then D.Exponent (V) = Exp
        and then D.Is_Negative (V) = Neg;
   end Ok;

   function Zero_Ok (Text : String) return Boolean is
      V : D.Decimal;
      O : D.Parse_Outcome;
   begin
      D.Parse (Text, V, O);
      return O = D.Decimal_Ok and then D.Is_Zero (V)
        and then not D.Is_Negative (V);
   end Zero_Ok;

   function Fails (Text : String; Kind : D.Parse_Outcome) return Boolean is
      V : D.Decimal;
      O : D.Parse_Outcome;
   begin
      D.Parse (Text, V, O);
      return O = Kind;
   end Fails;

   function Img (Text : String) return String is
      V : D.Decimal;
      O : D.Parse_Outcome;
   begin
      D.Parse (Text, V, O);
      return D.Image (V);
   end Img;

   procedure Test_Normalization (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Ok ("1.5", "15", -1, False), "1.5 -> 15e-1");
      Assert (Ok ("1500", "15", 2, False), "1500 -> 15e2 (trailing zeros)");
      Assert (Ok ("0.015", "15", -3, False), "0.015 -> 15e-3 (leading zeros)");
      Assert (Ok ("100", "1", 2, False), "100 -> 1e2");
      Assert (Ok ("1e3", "1", 3, False), "1e3 -> 1e3");
      Assert (Ok ("1.23e-4", "123", -6, False), "1.23e-4 -> 123e-6");
      Assert (Ok ("-42", "42", 0, True), "-42 -> -42e0");
   end Test_Normalization;

   procedure Test_Canonical_Equality (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      --  Distinct spellings of the same exact value normalize identically.
      Assert (Ok ("1.1", "11", -1, False), "1.1");
      Assert (Ok ("1.10", "11", -1, False), "1.10 equals 1.1");
      Assert (Ok ("1.100", "11", -1, False), "1.100 equals 1.1");
      Assert (Ok ("0.11e1", "11", -1, False), "0.11e1 equals 1.1");
   end Test_Canonical_Equality;

   procedure Test_Zero_Forms (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Zero_Ok ("0"), "0");
      Assert (Zero_Ok ("-0"), "-0 normalizes to zero (not negative)");
      Assert (Zero_Ok ("0.0"), "0.0");
      Assert (Zero_Ok ("0e5"), "0e5");
      Assert (Zero_Ok ("0.000"), "0.000");
   end Test_Zero_Forms;

   procedure Test_Image (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Img ("1500") = "1.5E3", "1500 image");
      Assert (Img ("0.015") = "1.5E-2", "0.015 image");
      Assert (Img ("-42") = "-4.2E1", "-42 image");
      Assert (Img ("100") = "1E2", "100 image");
      Assert (Img ("0") = "0", "zero image");
      Assert (Img ("1.23e-4") = "1.23E-4", "1.23e-4 image");
   end Test_Image;

   procedure Test_Rejects (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Fails ("", D.Decimal_Syntax), "empty");
      Assert (Fails ("01", D.Decimal_Syntax), "leading zero");
      Assert (Fails ("1.", D.Decimal_Syntax), "no fraction digit");
      Assert (Fails ("1e", D.Decimal_Syntax), "no exponent digit");
      Assert (Fails (".5", D.Decimal_Syntax), "no integer part");
      Assert (Fails ("+1", D.Decimal_Syntax), "plus sign");
      Assert (Fails ("1.2.3", D.Decimal_Syntax), "two decimal points");
      Assert (Fails ("abc", D.Decimal_Syntax), "not a number");
      Assert (Fails ("1 2", D.Decimal_Syntax), "embedded space");
   end Test_Rejects;

   procedure Test_Limits (T : in out Fixture) is
      pragma Unreferenced (T);
      Too_Many : constant String := (1 .. 41 => '1');
   begin
      Assert (Fails (Too_Many, D.Decimal_Too_Many_Digits),
              "41 significant digits exceeds the limit");
      Assert (Fails ("1e9999999", D.Decimal_Exponent_Range),
              "exponent out of range");
   end Test_Limits;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Decimals: normalization", Test_Normalization'Access));
      Suite.Add_Test
        (Caller.Create ("Decimals: canonical equality",
         Test_Canonical_Equality'Access));
      Suite.Add_Test
        (Caller.Create ("Decimals: zero forms", Test_Zero_Forms'Access));
      Suite.Add_Test
        (Caller.Create ("Decimals: image", Test_Image'Access));
      Suite.Add_Test
        (Caller.Create ("Decimals: rejects", Test_Rejects'Access));
      Suite.Add_Test
        (Caller.Create ("Decimals: limits", Test_Limits'Access));
   end Add_Tests;

end Decimals_Tests;
