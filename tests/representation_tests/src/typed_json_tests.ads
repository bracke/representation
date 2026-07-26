with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Typed_JSON_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Redaction (T : in out Fixture);
   procedure Test_Multi_Issue_Paths (T : in out Fixture);
   procedure Test_Decode_Valid (T : in out Fixture);
   procedure Test_Decode_Syntax (T : in out Fixture);
   procedure Test_Decode_Schema_Invalid (T : in out Fixture);
   procedure Test_Encode (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Typed_JSON_Tests;
