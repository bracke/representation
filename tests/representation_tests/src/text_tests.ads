with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Text_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Valid_Sequences (T : in out Fixture);
   procedure Test_Rejects_Overlong (T : in out Fixture);
   procedure Test_Rejects_Surrogates (T : in out Fixture);
   procedure Test_Rejects_Out_Of_Range (T : in out Fixture);
   procedure Test_Rejects_Malformed (T : in out Fixture);
   procedure Test_Scalar_Count (T : in out Fixture);
   procedure Test_Incremental_Split (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Text_Tests;
