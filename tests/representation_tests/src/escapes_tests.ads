with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Escapes_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Decode_Simple (T : in out Fixture);
   procedure Test_Decode_Unicode (T : in out Fixture);
   procedure Test_Decode_Surrogates (T : in out Fixture);
   procedure Test_Decode_Rejects (T : in out Fixture);
   procedure Test_Encode (T : in out Fixture);
   procedure Test_Roundtrip (T : in out Fixture);
   procedure Test_Overflow (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Escapes_Tests;
