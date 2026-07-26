with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;              use Representation;
with Representation.Inputs;
with Representation.Limits;
with Representation.Errors;
with Representation.JSON.Parser;

package body Parser_Tests is

   package Pr renames Representation.JSON.Parser;
   package Cfg renames Representation.Limits;
   use type Pr.Event_Kind;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   Max_Ev : constant := 128;
   type Kind_Seq is array (1 .. Max_Ev) of Pr.Event_Kind;

   --  Collect the event-kind stream up to (and including) the terminal event.
   procedure Run
     (Data  : aliased Byte_Array;
      Seq   : out Kind_Seq;
      N     : out Natural;
      Lim   : Cfg.Limits := Cfg.Default_Limits;
      Dedup : Boolean := True)
   is
      Src : aliased Representation.Inputs.Array_Source (Data'Access);
      P   : Pr.Parser (Src'Access, 64, 256, 32, 1024, 128);
      Ev  : Pr.Event;
   begin
      Pr.Start (P, Lim, Dedup);
      N := 0;
      loop
         Pr.Next (P, Ev);
         N := N + 1;
         Seq (N) := Ev.Kind;
         exit when Ev.Kind in Pr.End_Of_Input | Pr.Error or else N = Max_Ev;
      end loop;
   end Run;

   --  The stable error id if parsing ends in Error, else "".
   function Error_Of
     (Data  : aliased Byte_Array;
      Lim   : Cfg.Limits := Cfg.Default_Limits;
      Dedup : Boolean := True) return String
   is
      Src : aliased Representation.Inputs.Array_Source (Data'Access);
      P   : Pr.Parser (Src'Access, 64, 256, 32, 1024, 128);
      Ev  : Pr.Event;
   begin
      Pr.Start (P, Lim, Dedup);
      loop
         Pr.Next (P, Ev);
         exit when Ev.Kind in Pr.End_Of_Input | Pr.Error;
      end loop;
      return (if Ev.Kind = Pr.Error then Pr.Error_Id (P) else "");
   end Error_Of;

   procedure Test_Scalars (T : in out Fixture) is
      pragma Unreferenced (T);
      B_True : aliased constant Byte_Array := To_Bytes ("true");
      Num    : aliased constant Byte_Array := To_Bytes ("  -3.5e2 ");
      Src    : aliased Representation.Inputs.Array_Source (B_True'Access);
      P      : Pr.Parser (Src'Access, 64, 256, 32, 1024, 128);
      Ev     : Pr.Event;
      Seq    : Kind_Seq;
      N      : Natural;
   begin
      Pr.Start (P);
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Boolean_Value and then Ev.Bool, "true scalar");
      Assert (Ev.Depth = 0, "top-level scalar at depth 0");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.End_Of_Input, "then EOI");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.End_Of_Input, "terminal EOI is stable");

      Run (Num, Seq, N);
      Assert (N = 2, "number + EOI");
      Assert (Seq (1) = Pr.Number_Value, "number value");
   end Test_Scalars;

   procedure Test_Structure (T : in out Fixture) is
      pragma Unreferenced (T);
      Empty_O : aliased constant Byte_Array := To_Bytes ("{}");
      Empty_A : aliased constant Byte_Array := To_Bytes ("[]");
      Arr     : aliased constant Byte_Array := To_Bytes ("[1, 2, 3]");
      Seq     : Kind_Seq;
      N       : Natural;
   begin
      Run (Empty_O, Seq, N);
      Assert (N = 3 and then Seq (1) = Pr.Start_Object
              and then Seq (2) = Pr.End_Object
              and then Seq (3) = Pr.End_Of_Input, "empty object");

      Run (Empty_A, Seq, N);
      Assert (N = 3 and then Seq (1) = Pr.Start_Array
              and then Seq (2) = Pr.End_Array, "empty array");

      Run (Arr, Seq, N);
      Assert (N = 6, "[ 1 2 3 ] EOI");
      Assert (Seq (1) = Pr.Start_Array
              and then Seq (2) = Pr.Number_Value
              and then Seq (4) = Pr.Number_Value
              and then Seq (5) = Pr.End_Array, "array elements");
   end Test_Structure;

   procedure Test_Keys_And_Values (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array :=
        To_Bytes ("{""a"": 1, ""b"": ""hi"", ""c"": null}");
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      P    : Pr.Parser (Src'Access, 64, 256, 32, 1024, 128);
      Ev   : Pr.Event;
   begin
      Pr.Start (P);
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Start_Object, "start object");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Key and then To_String (Pr.Value (P)) = "a", "key a");
      Assert (Ev.Depth = 1, "member at depth 1");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Number_Value and then To_String (Pr.Value (P)) = "1",
              "value 1");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Key and then To_String (Pr.Value (P)) = "b", "key b");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.String_Value
              and then To_String (Pr.Value (P)) = "hi", "value hi");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Key and then To_String (Pr.Value (P)) = "c", "key c");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.Null_Value, "value null");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.End_Object, "end object");
      Pr.Next (P, Ev);
      Assert (Ev.Kind = Pr.End_Of_Input, "EOI");
   end Test_Keys_And_Values;

   procedure Test_Nesting_And_Depth (T : in out Fixture) is
      pragma Unreferenced (T);
      Nested : aliased constant Byte_Array :=
        To_Bytes ("{""a"": [ {""b"": [1]} ]}");
      Deep   : aliased constant Byte_Array := To_Bytes ("[[[[[1]]]]]");
      Lim    : constant Cfg.Limits := (Max_Depth => 3, others => <>);
      Src    : aliased Representation.Inputs.Array_Source (Nested'Access);
      P      : Pr.Parser (Src'Access, 64, 256, 32, 1024, 128);
      Ev     : Pr.Event;
      Max_D  : Depth_Count := 0;
   begin
      Pr.Start (P);
      loop
         Pr.Next (P, Ev);
         if Ev.Depth > Max_D then
            Max_D := Ev.Depth;
         end if;
         exit when Ev.Kind in Pr.End_Of_Input | Pr.Error;
      end loop;
      Assert (Ev.Kind = Pr.End_Of_Input, "well-nested parses");
      Assert (Max_D = 4, "deepest event at depth 4 (obj>arr>obj>arr)");

      Assert (Error_Of (Deep, Lim) = Representation.Errors.Limit_Max_Depth,
              "depth limit enforced");
   end Test_Nesting_And_Depth;

   procedure Test_Grammar_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      Missing_Comma : aliased constant Byte_Array := To_Bytes ("[1 2]");
      Missing_Colon : aliased constant Byte_Array := To_Bytes ("{""a"" 1}");
      Empty_Member  : aliased constant Byte_Array := To_Bytes ("{""a"":}");
      Bare_Comma    : aliased constant Byte_Array := To_Bytes ("[,]");
      Nonstring_Key : aliased constant Byte_Array := To_Bytes ("{1:2}");
      Trailing_Elem : aliased constant Byte_Array := To_Bytes ("[1,]");
      Empty_Doc     : aliased constant Byte_Array := To_Bytes ("   ");
      Open_Object   : aliased constant Byte_Array := To_Bytes ("{");
   begin
      Assert (Error_Of (Missing_Comma) = Representation.Errors.Json_Invalid_Token,
              "missing comma");
      Assert (Error_Of (Missing_Colon) = Representation.Errors.Json_Invalid_Token,
              "missing colon");
      Assert (Error_Of (Empty_Member) = Representation.Errors.Json_Invalid_Token,
              "empty member value");
      Assert (Error_Of (Bare_Comma) = Representation.Errors.Json_Invalid_Token,
              "bare comma in array");
      Assert (Error_Of (Nonstring_Key) = Representation.Errors.Json_Invalid_Token,
              "non-string key");
      Assert (Error_Of (Trailing_Elem) = Representation.Errors.Json_Invalid_Token,
              "trailing comma in array");
      Assert (Error_Of (Empty_Doc) = Representation.Errors.Json_Unexpected_End,
              "empty document");
      Assert (Error_Of (Open_Object) = Representation.Errors.Json_Unexpected_End,
              "unterminated object");
   end Test_Grammar_Errors;

   procedure Test_Trailing_Input (T : in out Fixture) is
      pragma Unreferenced (T);
      Two_Values : aliased constant Byte_Array := To_Bytes ("123 456");
      Junk_After : aliased constant Byte_Array := To_Bytes ("{} null");
   begin
      Assert (Error_Of (Two_Values) = Representation.Errors.Json_Trailing_Input,
              "second top-level value rejected");
      Assert (Error_Of (Junk_After) = Representation.Errors.Json_Trailing_Input,
              "extra trailing value rejected");
   end Test_Trailing_Input;

   procedure Test_Limits (T : in out Fixture) is
      pragma Unreferenced (T);
      Members  : aliased constant Byte_Array :=
        To_Bytes ("{""a"":1,""b"":2,""c"":3}");
      Elements : aliased constant Byte_Array := To_Bytes ("[1,2,3]");
      Budget   : aliased constant Byte_Array := To_Bytes ("[1,2,3,4,5]");
      Total    : aliased constant Byte_Array := To_Bytes ("[1,2,3]");
      Lim_M : constant Cfg.Limits := (Max_Object_Members => 2, others => <>);
      Lim_E : constant Cfg.Limits := (Max_Array_Elements => 2, others => <>);
      Lim_W : constant Cfg.Limits := (Work_Budget => 3, others => <>);
      Lim_V : constant Cfg.Limits := (Max_Total_Values => 2, others => <>);
   begin
      Assert (Error_Of (Members, Lim_M) = Representation.Errors.Limit_Max_Members,
              "object member limit");
      Assert (Error_Of (Elements, Lim_E)
              = Representation.Errors.Limit_Max_Elements,
              "array element limit");
      Assert (Error_Of (Budget, Lim_W) = Representation.Errors.Limit_Work_Budget,
              "work budget exhaustion");
      Assert (Error_Of (Total, Lim_V) = Representation.Errors.Limit_Work_Budget,
              "total-values limit");
   end Test_Limits;

   procedure Test_Duplicate_Keys (T : in out Fixture) is
      pragma Unreferenced (T);
      Dup       : aliased constant Byte_Array :=
        To_Bytes ("{""a"":1,""a"":2}");
      Sibling   : aliased constant Byte_Array :=
        To_Bytes ("[{""a"":1},{""a"":2}]");
      Nested    : aliased constant Byte_Array :=
        To_Bytes ("{""a"":1,""b"":{""a"":2}}");
      Seq : Kind_Seq;
      N   : Natural;
   begin
      Assert (Error_Of (Dup) = Representation.Errors.Object_Duplicate_Field,
              "duplicate key within one object rejected");

      --  Same name in sibling / nested objects is not a duplicate.
      Run (Sibling, Seq, N);
      Assert (Seq (N) = Pr.End_Of_Input, "sibling reuse of a name is fine");
      Run (Nested, Seq, N);
      Assert (Seq (N) = Pr.End_Of_Input, "nested reuse of a name is fine");

      --  With detection disabled the duplicate is passed through.
      Run (Dup, Seq, N, Dedup => False);
      Assert (Seq (N) = Pr.End_Of_Input,
              "duplicates pass through when detection is off");
   end Test_Duplicate_Keys;

   procedure Test_Streaming (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array :=
        To_Bytes ("{""items"": [1, {""k"": true}, null]}");
      Src1 : aliased Representation.Inputs.Array_Source (Data'Access);
      Src2 : aliased Representation.Inputs.Array_Source (Data'Access);
      P1   : Pr.Parser (Src1'Access, 1, 256, 32, 1024, 128);   --  1-byte reads
      P2   : Pr.Parser (Src2'Access, 64, 256, 32, 1024, 128);
      E1, E2 : Pr.Event;
   begin
      Pr.Start (P1);
      Pr.Start (P2);
      loop
         Pr.Next (P1, E1);
         Pr.Next (P2, E2);
         Assert (E1.Kind = E2.Kind, "event streams match across read sizes");
         exit when E1.Kind in Pr.End_Of_Input | Pr.Error;
      end loop;
      Assert (E1.Kind = Pr.End_Of_Input, "streamed parse completes");
   end Test_Streaming;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Parser: scalars", Test_Scalars'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: structure", Test_Structure'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: keys and values", Test_Keys_And_Values'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: nesting and depth",
         Test_Nesting_And_Depth'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: grammar errors", Test_Grammar_Errors'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: trailing input", Test_Trailing_Input'Access));
      Suite.Add_Test (Caller.Create ("Parser: limits", Test_Limits'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: duplicate keys", Test_Duplicate_Keys'Access));
      Suite.Add_Test
        (Caller.Create ("Parser: streaming", Test_Streaming'Access));
   end Add_Tests;

end Parser_Tests;
