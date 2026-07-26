with Foundation_Tests;
with Text_Tests;
with Numbers_Tests;
with Decimals_Tests;
with Timestamps_Tests;
with Escapes_Tests;

package body All_Suites is

   function Suite return AUnit.Test_Suites.Access_Test_Suite is
      Result : constant AUnit.Test_Suites.Access_Test_Suite :=
        AUnit.Test_Suites.New_Suite;
   begin
      Foundation_Tests.Add_Tests (Result);
      Text_Tests.Add_Tests (Result);
      Numbers_Tests.Add_Tests (Result);
      Decimals_Tests.Add_Tests (Result);
      Timestamps_Tests.Add_Tests (Result);
      Escapes_Tests.Add_Tests (Result);
      return Result;
   end Suite;

end All_Suites;
