with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Hardening_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Malformed_Corpus (T : in out Fixture);
   procedure Test_Fuzz_No_Crash (T : in out Fixture);
   procedure Test_Canonical_Properties (T : in out Fixture);
   procedure Test_Source_Failure (T : in out Fixture);
   procedure Test_Sink_Failure (T : in out Fixture);
   procedure Test_Concurrency (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Hardening_Tests;
