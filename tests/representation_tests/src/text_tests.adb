with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;      use Representation;
with Representation.Text;

package body Text_Tests is

   package Txt renames Representation.Text;

   --  Well-known code points as UTF-8 byte sequences.
   ASCII : constant Byte_Array := (1 => 16#61#);                       --  "a"
   E_Acute : constant Byte_Array := (16#C3#, 16#A9#);             --  U+00E9
   Euro  : constant Byte_Array := (16#E2#, 16#82#, 16#AC#);       --  U+20AC
   Grin  : constant Byte_Array := (16#F0#, 16#9F#, 16#98#, 16#80#); --  U+1F600

   procedure Test_Valid_Sequences (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Txt.Valid_Utf8 (ASCII), "ASCII valid");
      Assert (Txt.Valid_Utf8 (E_Acute), "2-byte valid");
      Assert (Txt.Valid_Utf8 (Euro), "3-byte valid");
      Assert (Txt.Valid_Utf8 (Grin), "4-byte valid");
      Assert (Txt.Valid_Utf8 (ASCII & E_Acute & Euro & Grin), "mixed valid");
      Assert (Txt.Valid_Utf8 (Byte_Array'(1 .. 0 => 0)), "empty is valid");
   end Test_Valid_Sequences;

   procedure Test_Rejects_Overlong (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (not Txt.Valid_Utf8 ((16#C0#, 16#80#)), "overlong 2-byte NUL");
      Assert (not Txt.Valid_Utf8 ((16#C1#, 16#BF#)), "overlong 2-byte");
      Assert (not Txt.Valid_Utf8 ((16#E0#, 16#80#, 16#80#)), "overlong 3-byte");
      Assert (not Txt.Valid_Utf8 ((16#F0#, 16#80#, 16#80#, 16#80#)),
              "overlong 4-byte");
   end Test_Rejects_Overlong;

   procedure Test_Rejects_Surrogates (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      --  U+D800 (ED A0 80) and U+DFFF (ED BF BF) must be rejected.
      Assert (not Txt.Valid_Utf8 ((16#ED#, 16#A0#, 16#80#)), "U+D800 rejected");
      Assert (not Txt.Valid_Utf8 ((16#ED#, 16#BF#, 16#BF#)), "U+DFFF rejected");
      --  U+D7FF (ED 9F BF) is the last valid before the surrogate block.
      Assert (Txt.Valid_Utf8 ((16#ED#, 16#9F#, 16#BF#)), "U+D7FF accepted");
   end Test_Rejects_Surrogates;

   procedure Test_Rejects_Out_Of_Range (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      --  U+110000 (F4 90 80 80) is beyond U+10FFFF.
      Assert (not Txt.Valid_Utf8 ((16#F4#, 16#90#, 16#80#, 16#80#)),
              "U+110000 rejected");
      --  U+10FFFF (F4 8F BF BF) is the last valid code point.
      Assert (Txt.Valid_Utf8 ((16#F4#, 16#8F#, 16#BF#, 16#BF#)),
              "U+10FFFF accepted");
      Assert (not Txt.Valid_Utf8 ((16#F5#, 16#80#, 16#80#, 16#80#)),
              "F5 lead rejected");
   end Test_Rejects_Out_Of_Range;

   procedure Test_Rejects_Malformed (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (not Txt.Valid_Utf8 ((1 => 16#80#)), "stray continuation");
      Assert (not Txt.Valid_Utf8 ((1 => 16#C3#)), "truncated 2-byte");
      Assert (not Txt.Valid_Utf8 ((16#E2#, 16#82#)), "truncated 3-byte");
      Assert (not Txt.Valid_Utf8 ((16#C3#, 16#41#)), "bad continuation byte");
      Assert (not Txt.Valid_Utf8 ((1 => 16#FF#)), "0xFF never valid");
   end Test_Rejects_Malformed;

   procedure Test_Scalar_Count (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Txt.Scalar_Count_Of (ASCII & Euro & Grin) = 3,
              "three scalars regardless of byte length");
      Assert (Txt.Scalar_Count_Of ((16#C0#, 16#80#)) = 0,
              "invalid input counts zero scalars");
   end Test_Scalar_Count;

   procedure Test_Incremental_Split (T : in out Fixture) is
      pragma Unreferenced (T);
      use type Representation.Text.Feed_Result;
      V : Representation.Text.Validator := Representation.Text.New_Validator;
      R : Representation.Text.Feed_Result;
   begin
      --  Split the 3-byte Euro across two feeds.
      Representation.Text.Feed (V, (16#E2#, 16#82#), R);
      Assert (R = Representation.Text.Feeding_Ok, "partial feed ok");
      Assert (not Representation.Text.Is_Complete (V),
              "pending continuation is not complete");
      Representation.Text.Feed (V, (1 => 16#AC#), R);
      Assert (Representation.Text.Is_Complete (V),
              "completed across the chunk boundary");
      --  A fresh validator that then sees a stray continuation fails.
      declare
         W : Representation.Text.Validator :=
           Representation.Text.New_Validator;
         RW : Representation.Text.Feed_Result;
      begin
         Representation.Text.Feed (W, (1 => 16#80#), RW);
         Assert (RW = Representation.Text.Feeding_Invalid, "stray byte fails");
         Assert (Representation.Text.Failed (W), "failed flag set");
      end;
   end Test_Incremental_Split;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Text: valid sequences", Test_Valid_Sequences'Access));
      Suite.Add_Test
        (Caller.Create ("Text: rejects overlong", Test_Rejects_Overlong'Access));
      Suite.Add_Test
        (Caller.Create ("Text: rejects surrogates",
         Test_Rejects_Surrogates'Access));
      Suite.Add_Test
        (Caller.Create ("Text: rejects out of range",
         Test_Rejects_Out_Of_Range'Access));
      Suite.Add_Test
        (Caller.Create ("Text: rejects malformed", Test_Rejects_Malformed'Access));
      Suite.Add_Test
        (Caller.Create ("Text: scalar count", Test_Scalar_Count'Access));
      Suite.Add_Test
        (Caller.Create ("Text: incremental split", Test_Incremental_Split'Access));
   end Add_Tests;

end Text_Tests;
