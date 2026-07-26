with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Documents_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Scalars (T : in out Fixture);
   procedure Test_Array (T : in out Fixture);
   procedure Test_Object (T : in out Fixture);
   procedure Test_Nested (T : in out Fixture);
   procedure Test_Equality (T : in out Fixture);
   procedure Test_Number_Equality (T : in out Fixture);
   procedure Test_Overflow (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Documents_Tests;
