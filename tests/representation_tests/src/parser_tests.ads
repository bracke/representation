with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Parser_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Scalars (T : in out Fixture);
   procedure Test_Structure (T : in out Fixture);
   procedure Test_Keys_And_Values (T : in out Fixture);
   procedure Test_Nesting_And_Depth (T : in out Fixture);
   procedure Test_Grammar_Errors (T : in out Fixture);
   procedure Test_Trailing_Input (T : in out Fixture);
   procedure Test_Limits (T : in out Fixture);
   procedure Test_Duplicate_Keys (T : in out Fixture);
   procedure Test_Streaming (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Parser_Tests;
