with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Typed_Codecs_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Decode_Order_Independent (T : in out Fixture);
   procedure Test_Decode_Missing (T : in out Fixture);
   procedure Test_Decode_Syntax (T : in out Fixture);
   procedure Test_Encode (T : in out Fixture);
   procedure Test_Round_Trip (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Typed_Codecs_Tests;
