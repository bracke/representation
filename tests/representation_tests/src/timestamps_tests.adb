with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation.Timestamps;

package body Timestamps_Tests is

   package Ts renames Representation.Timestamps;
   use type Ts.Parse_Outcome;

   --  Parse then canonically render; "ERR" on any failure.
   function Canon (Text : String; Require_Utc : Boolean := False) return String is
      V : Ts.Timestamp;
      O : Ts.Parse_Outcome;
   begin
      Ts.Parse (Text, V, O, Require_Utc);
      return (if O = Ts.Ts_Ok then Ts.Canonical (V) else "ERR");
   end Canon;

   function Result (Text : String; Require_Utc : Boolean := False)
     return Ts.Parse_Outcome
   is
      V : Ts.Timestamp;
      O : Ts.Parse_Outcome;
   begin
      Ts.Parse (Text, V, O, Require_Utc);
      return O;
   end Result;

   procedure Test_Utc_Roundtrip (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Canon ("2026-07-26T14:30:00Z") = "2026-07-26T14:30:00Z",
              "UTC round-trips");
      Assert (Canon ("2026-07-26t14:30:00z") = "2026-07-26T14:30:00Z",
              "lowercase t/z accepted, canonical uppercase");
   end Test_Utc_Roundtrip;

   procedure Test_Offset_Normalization (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Canon ("2026-07-26T14:30:00+02:00") = "2026-07-26T12:30:00Z",
              "+02:00 normalizes to UTC");
      Assert (Canon ("2026-07-26T14:30:00-05:00") = "2026-07-26T19:30:00Z",
              "-05:00 normalizes to UTC");
      Assert (Canon ("2026-07-26T12:30:00+00:00") = "2026-07-26T12:30:00Z",
              "+00:00 equals Z");
   end Test_Offset_Normalization;

   procedure Test_Day_Boundary (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Canon ("2026-07-26T00:30:00+02:00") = "2026-07-25T22:30:00Z",
              "offset crosses to the previous day");
      Assert (Canon ("2026-07-26T23:30:00-02:00") = "2026-07-27T01:30:00Z",
              "offset crosses to the next day");
      --  Cross a month and a leap-year boundary at once.
      Assert (Canon ("2024-03-01T00:30:00+02:00") = "2024-02-29T22:30:00Z",
              "crosses into Feb 29 of a leap year");
   end Test_Day_Boundary;

   procedure Test_Fractional (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Canon ("2026-07-26T14:30:00.5Z") = "2026-07-26T14:30:00.5Z",
              "fractional preserved");
      Assert (Canon ("2026-07-26T14:30:00.500Z") = "2026-07-26T14:30:00.5Z",
              "trailing fractional zeros trimmed");
      Assert (Canon ("2026-07-26T14:30:00.123456789Z")
                = "2026-07-26T14:30:00.123456789Z",
              "nanosecond precision preserved");
      Assert (Canon ("2026-07-26T14:30:00.0Z") = "2026-07-26T14:30:00Z",
              "all-zero fraction omitted");
   end Test_Fractional;

   procedure Test_Require_Utc (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Result ("2026-07-26T14:30:00+02:00", Require_Utc => True)
                = Ts.Ts_Requires_Utc, "offset rejected when UTC required");
      Assert (Result ("2026-07-26T14:30:00Z", Require_Utc => True) = Ts.Ts_Ok,
              "Z accepted when UTC required");
      Assert (Result ("2026-07-26T14:30:00+00:00", Require_Utc => True)
                = Ts.Ts_Ok, "+00:00 accepted when UTC required");
   end Test_Require_Utc;

   procedure Test_Range_And_Leap (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Result ("2026-07-26T23:59:60Z") = Ts.Ts_Range,
              "leap second (SS=60) rejected");
      Assert (Result ("2026-13-01T00:00:00Z") = Ts.Ts_Range, "month 13");
      Assert (Result ("2026-02-30T00:00:00Z") = Ts.Ts_Range, "Feb 30");
      Assert (Result ("2023-02-29T00:00:00Z") = Ts.Ts_Range, "Feb 29 non-leap");
      Assert (Result ("2024-02-29T00:00:00Z") = Ts.Ts_Ok, "Feb 29 leap ok");
      Assert (Result ("2026-07-26T24:00:00Z") = Ts.Ts_Range, "hour 24");
   end Test_Range_And_Leap;

   procedure Test_Syntax (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Result ("2026-07-26T14:30:00") = Ts.Ts_Syntax, "missing timezone");
      Assert (Result ("2026-07-26 14:30:00Z") = Ts.Ts_Syntax, "space not T");
      Assert (Result ("") = Ts.Ts_Syntax, "empty");
      Assert (Result ("2026/07/26T14:30:00Z") = Ts.Ts_Syntax, "wrong separator");
      Assert (Result ("2026-07-26T14:30:00.1234567890Z") = Ts.Ts_Precision,
              "sub-nanosecond precision rejected");
   end Test_Syntax;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Timestamps: UTC round-trip", Test_Utc_Roundtrip'Access));
      Suite.Add_Test
        (Caller.Create ("Timestamps: offset normalization",
         Test_Offset_Normalization'Access));
      Suite.Add_Test
        (Caller.Create ("Timestamps: day boundary", Test_Day_Boundary'Access));
      Suite.Add_Test
        (Caller.Create ("Timestamps: fractional", Test_Fractional'Access));
      Suite.Add_Test
        (Caller.Create ("Timestamps: require UTC", Test_Require_Utc'Access));
      Suite.Add_Test
        (Caller.Create ("Timestamps: range and leap",
         Test_Range_And_Leap'Access));
      Suite.Add_Test
        (Caller.Create ("Timestamps: syntax", Test_Syntax'Access));
   end Add_Tests;

end Timestamps_Tests;
