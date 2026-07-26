with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Timestamps_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Utc_Roundtrip (T : in out Fixture);
   procedure Test_Offset_Normalization (T : in out Fixture);
   procedure Test_Day_Boundary (T : in out Fixture);
   procedure Test_Fractional (T : in out Fixture);
   procedure Test_Require_Utc (T : in out Fixture);
   procedure Test_Range_And_Leap (T : in out Fixture);
   procedure Test_Syntax (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Timestamps_Tests;
