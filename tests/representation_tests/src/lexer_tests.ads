with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Lexer_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Structural (T : in out Fixture);
   procedure Test_Literals (T : in out Fixture);
   procedure Test_Values (T : in out Fixture);
   procedure Test_Locations (T : in out Fixture);
   procedure Test_Streaming (T : in out Fixture);
   procedure Test_Malformed (T : in out Fixture);
   procedure Test_Limits (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Lexer_Tests;
