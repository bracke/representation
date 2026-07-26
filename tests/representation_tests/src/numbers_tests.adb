with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Interfaces;
with Representation.Numbers;

package body Numbers_Tests is

   package N renames Representation.Numbers;
   use type N.Parse_Outcome;
   use type Interfaces.Unsigned_64;

   function Signed_Ok (Text : String; Expect : Long_Long_Integer) return Boolean
   is
      V : N.Signed_Value;
      O : N.Parse_Outcome;
   begin
      N.Parse_Signed (Text, V, O);
      return O = N.Number_Ok and then V = Expect;
   end Signed_Ok;

   function Signed_Fails (Text : String; Kind : N.Parse_Outcome) return Boolean
   is
      V : N.Signed_Value;
      O : N.Parse_Outcome;
   begin
      N.Parse_Signed (Text, V, O);
      return O = Kind;
   end Signed_Fails;

   function Unsigned_Ok
     (Text : String; Expect : Interfaces.Unsigned_64) return Boolean
   is
      V : N.Unsigned_Value;
      O : N.Parse_Outcome;
   begin
      N.Parse_Unsigned (Text, V, O);
      return O = N.Number_Ok and then V = Expect;
   end Unsigned_Ok;

   function Unsigned_Fails (Text : String; Kind : N.Parse_Outcome) return Boolean
   is
      V : N.Unsigned_Value;
      O : N.Parse_Outcome;
   begin
      N.Parse_Unsigned (Text, V, O);
      return O = Kind;
   end Unsigned_Fails;

   procedure Test_Signed_Values (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Signed_Ok ("0", 0), "zero");
      Assert (Signed_Ok ("-0", 0), "negative zero is zero");
      Assert (Signed_Ok ("42", 42), "positive");
      Assert (Signed_Ok ("-42", -42), "negative");
   end Test_Signed_Values;

   procedure Test_Signed_Boundaries (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Signed_Ok ("9223372036854775807", Long_Long_Integer'Last),
              "signed max");
      Assert (Signed_Ok ("-9223372036854775808", Long_Long_Integer'First),
              "signed min");
      Assert (Signed_Fails ("9223372036854775808", N.Number_Overflow),
              "max+1 overflows, never wraps");
      Assert (Signed_Fails ("-9223372036854775809", N.Number_Overflow),
              "min-1 overflows");
   end Test_Signed_Boundaries;

   procedure Test_Signed_Rejects (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Signed_Fails ("", N.Number_Syntax), "empty");
      Assert (Signed_Fails ("-", N.Number_Syntax), "lone minus");
      Assert (Signed_Fails ("01", N.Number_Syntax), "leading zero");
      Assert (Signed_Fails ("+1", N.Number_Syntax), "plus sign");
      Assert (Signed_Fails ("1.5", N.Number_Syntax), "fraction is not integer");
      Assert (Signed_Fails ("1e3", N.Number_Syntax), "exponent is not integer");
      Assert (Signed_Fails ("12x", N.Number_Syntax), "trailing junk");
   end Test_Signed_Rejects;

   procedure Test_Unsigned_Values (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Unsigned_Ok ("0", 0), "zero");
      Assert (Unsigned_Ok ("42", 42), "positive");
      Assert (Unsigned_Fails ("-5", N.Number_Syntax), "no sign allowed");
      Assert (Unsigned_Fails ("007", N.Number_Syntax), "leading zeros");
   end Test_Unsigned_Values;

   procedure Test_Unsigned_Boundaries (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Unsigned_Ok ("18446744073709551615", Interfaces.Unsigned_64'Last),
              "unsigned max");
      Assert (Unsigned_Fails ("18446744073709551616", N.Number_Overflow),
              "unsigned max+1 overflows");
   end Test_Unsigned_Boundaries;

   procedure Test_Images (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (N.Image (Long_Long_Integer'First) = "-9223372036854775808",
              "signed min image");
      Assert (N.Image (Interfaces.Unsigned_64'Last) = "18446744073709551615",
              "unsigned max image");
      Assert (N.Image (Long_Long_Integer'(0)) = "0", "zero image");
   end Test_Images;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Numbers: signed values", Test_Signed_Values'Access));
      Suite.Add_Test
        (Caller.Create ("Numbers: signed boundaries",
         Test_Signed_Boundaries'Access));
      Suite.Add_Test
        (Caller.Create ("Numbers: signed rejects", Test_Signed_Rejects'Access));
      Suite.Add_Test
        (Caller.Create ("Numbers: unsigned values",
         Test_Unsigned_Values'Access));
      Suite.Add_Test
        (Caller.Create ("Numbers: unsigned boundaries",
         Test_Unsigned_Boundaries'Access));
      Suite.Add_Test
        (Caller.Create ("Numbers: images", Test_Images'Access));
   end Add_Tests;

end Numbers_Tests;
