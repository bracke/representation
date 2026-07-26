with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Schemas_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Build_And_Introspect (T : in out Fixture);
   procedure Test_Immutable_After_Finalize (T : in out Fixture);
   procedure Test_Validate_Ok (T : in out Fixture);
   procedure Test_Validate_Type_Mismatch (T : in out Fixture);
   procedure Test_Validate_Missing_And_Unknown (T : in out Fixture);
   procedure Test_Compatibility (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Schemas_Tests;
