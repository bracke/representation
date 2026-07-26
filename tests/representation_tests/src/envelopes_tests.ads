with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Envelopes_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Envelope (T : in out Fixture);
   procedure Test_Envelope_Errors (T : in out Fixture);
   procedure Test_Registry (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Envelopes_Tests;
