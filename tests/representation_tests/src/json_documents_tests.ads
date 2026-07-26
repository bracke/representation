with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package JSON_Documents_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Decode_Scalars (T : in out Fixture);
   procedure Test_Decode_Structure (T : in out Fixture);
   procedure Test_Decode_Escapes (T : in out Fixture);
   procedure Test_Decode_Errors (T : in out Fixture);
   procedure Test_Round_Trip (T : in out Fixture);
   procedure Test_Encode_Styles (T : in out Fixture);
   procedure Test_Canonical_Reproducible (T : in out Fixture);
   procedure Test_Canonical_Idempotent (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end JSON_Documents_Tests;
