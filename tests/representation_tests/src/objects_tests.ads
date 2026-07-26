with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Objects_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Fields (T : in out Fixture);
   procedure Test_Lookup_Order_Independent (T : in out Fixture);
   procedure Test_Validate_Required (T : in out Fixture);
   procedure Test_Validate_Unknown_Policy (T : in out Fixture);
   procedure Test_Validate_Duplicate (T : in out Fixture);
   procedure Test_Encode_Canonical_Names (T : in out Fixture);
   procedure Test_Arrays_Reader (T : in out Fixture);
   procedure Test_Extensions (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Objects_Tests;
