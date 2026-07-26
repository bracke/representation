with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Decimals_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Normalization (T : in out Fixture);
   procedure Test_Canonical_Equality (T : in out Fixture);
   procedure Test_Zero_Forms (T : in out Fixture);
   procedure Test_Image (T : in out Fixture);
   procedure Test_Rejects (T : in out Fixture);
   procedure Test_Limits (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Decimals_Tests;
