with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Versions_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Resolve (T : in out Fixture);
   procedure Test_Version_Immutable (T : in out Fixture);
   procedure Test_Migration_Graph (T : in out Fixture);
   procedure Test_Migrate_Apply (T : in out Fixture);
   procedure Test_Migrate_Errors (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Versions_Tests;
