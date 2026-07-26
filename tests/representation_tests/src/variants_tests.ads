with AUnit.Test_Fixtures;
with AUnit.Test_Suites;

package Variants_Tests is

   type Fixture is new AUnit.Test_Fixtures.Test_Fixture with null record;

   procedure Test_Dispatch (T : in out Fixture);
   procedure Test_Dispatch_Errors (T : in out Fixture);
   procedure Test_Put_Discriminator (T : in out Fixture);
   procedure Test_References (T : in out Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite);

end Variants_Tests;
