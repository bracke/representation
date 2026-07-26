with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Typed_Scalar_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Values_Get (T : in out Fixture);
   procedure Test_Values_Put (T : in out Fixture);
   procedure Test_Values_Errors (T : in out Fixture);
   procedure Test_Optionals (T : in out Fixture);
   procedure Test_Enums (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Typed_Scalar_Tests;
