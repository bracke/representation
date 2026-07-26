with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Foundation_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Identifiers (T : in out Fixture);
   procedure Test_Path_Render (T : in out Fixture);
   procedure Test_Path_Bracket_And_Truncation (T : in out Fixture);
   procedure Test_Results (T : in out Fixture);
   procedure Test_Diagnostics (T : in out Fixture);
   procedure Test_Limits (T : in out Fixture);
   procedure Test_Buffers (T : in out Fixture);
   procedure Test_Array_Source (T : in out Fixture);
   procedure Test_Version (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Foundation_Tests;
