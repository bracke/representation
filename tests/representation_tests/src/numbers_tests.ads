with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Numbers_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Signed_Values (T : in out Fixture);
   procedure Test_Signed_Boundaries (T : in out Fixture);
   procedure Test_Signed_Rejects (T : in out Fixture);
   procedure Test_Unsigned_Values (T : in out Fixture);
   procedure Test_Unsigned_Boundaries (T : in out Fixture);
   procedure Test_Images (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Numbers_Tests;
