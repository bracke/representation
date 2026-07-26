with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Models_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Metadata (T : in out Fixture);
   procedure Test_Links (T : in out Fixture);
   procedure Test_Pagination (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Models_Tests;
