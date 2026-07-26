with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;              use Representation;
with Representation.Inputs;
with Representation.Limits;
with Representation.Errors;
with Representation.JSON.Lexer;

package body Lexer_Tests is

   package Lx renames Representation.JSON.Lexer;
   use type Lx.Token_Kind;

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

   Max_Toks : constant := 64;
   type Kind_Array is array (1 .. Max_Toks) of Lx.Token_Kind;

   procedure Lex_All
     (Data     : aliased Byte_Array;
      Read_Cap : Positive;
      Kinds    : out Kind_Array;
      Count    : out Natural)
   is
      Src : aliased Representation.Inputs.Array_Source (Data'Access);
      L   : Lx.Lexer (Src'Access, Read_Cap, Value_Capacity => 256);
      Tok : Lx.Token;
   begin
      Lx.Start (L);
      Count := 0;
      loop
         Lx.Next (L, Tok);
         Count := Count + 1;
         Kinds (Count) := Tok.Kind;
         exit when Tok.Kind in Lx.Tok_End_Of_Input | Lx.Tok_Error
           or else Count = Max_Toks;
      end loop;
   end Lex_All;

   function Value_At
     (Data : aliased Byte_Array; Which : Positive; Read_Cap : Positive := 256)
      return String
   is
      Src : aliased Representation.Inputs.Array_Source (Data'Access);
      L   : Lx.Lexer (Src'Access, Read_Cap, 256);
      Tok : Lx.Token;
   begin
      Lx.Start (L);
      for I in 1 .. Which loop
         Lx.Next (L, Tok);
      end loop;
      return To_String (Lx.Value (L));
   end Value_At;

   function Token_At
     (Data : aliased Byte_Array; Which : Positive) return Lx.Token
   is
      Src : aliased Representation.Inputs.Array_Source (Data'Access);
      L   : Lx.Lexer (Src'Access, 256, 256);
      Tok : Lx.Token;
   begin
      Lx.Start (L);
      for I in 1 .. Which loop
         Lx.Next (L, Tok);
      end loop;
      return Tok;
   end Token_At;

   function Error_Id_Of (Data : aliased Byte_Array) return String is
      Src : aliased Representation.Inputs.Array_Source (Data'Access);
      L   : Lx.Lexer (Src'Access, 256, 256);
      Tok : Lx.Token;
   begin
      Lx.Start (L);
      loop
         Lx.Next (L, Tok);
         exit when Tok.Kind in Lx.Tok_End_Of_Input | Lx.Tok_Error;
      end loop;
      return (if Tok.Kind = Lx.Tok_Error then Lx.Error_Id (L) else "");
   end Error_Id_Of;

   procedure Test_Structural (T : in out Fixture) is
      pragma Unreferenced (T);
      Data  : aliased constant Byte_Array := To_Bytes ("{}[]:,");
      Kinds : Kind_Array;
      Count : Natural;
   begin
      Lex_All (Data, 8, Kinds, Count);
      Assert (Count = 7, "seven tokens incl EOI");
      Assert (Kinds (1) = Lx.Tok_Begin_Object, "{");
      Assert (Kinds (2) = Lx.Tok_End_Object, "}");
      Assert (Kinds (3) = Lx.Tok_Begin_Array, "[");
      Assert (Kinds (4) = Lx.Tok_End_Array, "]");
      Assert (Kinds (5) = Lx.Tok_Name_Separator, ":");
      Assert (Kinds (6) = Lx.Tok_Value_Separator, ",");
      Assert (Kinds (7) = Lx.Tok_End_Of_Input, "EOI");
   end Test_Structural;

   procedure Test_Literals (T : in out Fixture) is
      pragma Unreferenced (T);
      Data  : aliased constant Byte_Array := To_Bytes ("true false null");
      Kinds : Kind_Array;
      Count : Natural;
   begin
      Lex_All (Data, 4, Kinds, Count);
      Assert (Count = 4, "three literals + EOI");
      Assert (Kinds (1) = Lx.Tok_True, "true");
      Assert (Kinds (2) = Lx.Tok_False, "false");
      Assert (Kinds (3) = Lx.Tok_Null, "null");
   end Test_Literals;

   procedure Test_Values (T : in out Fixture) is
      pragma Unreferenced (T);
      Str  : aliased constant Byte_Array := To_Bytes ("""hi""");
      Num  : aliased constant Byte_Array := To_Bytes ("-12.5e3");
      Esc  : aliased constant Byte_Array := To_Bytes ("""a\""b""");
   begin
      Assert (Value_At (Str, 1) = "hi", "string content captured");
      Assert (Value_At (Num, 1) = "-12.5e3", "number text captured");
      --  Raw content keeps escapes intact (backslash-quote-b).
      Assert (Value_At (Esc, 1) = "a\""b", "escapes kept raw in string value");
   end Test_Values;

   procedure Test_Locations (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array :=
        [16#0A#, 16#0A#] & To_Bytes ("  true");
      Tok  : constant Lx.Token := Token_At (Data, 1);
   begin
      Assert (Tok.Kind = Lx.Tok_True, "true token");
      Assert (Tok.Line = 3, "two newlines -> line 3");
      Assert (Tok.Column = 3, "two leading spaces -> column 3");
      Assert (Tok.Offset = 4, "offset counts LFs and spaces");
   end Test_Locations;

   procedure Test_Streaming (T : in out Fixture) is
      pragma Unreferenced (T);
      Data   : aliased constant Byte_Array := To_Bytes ("{""ab"":123}");
      K1, K2 : Kind_Array;
      C1, C2 : Natural;
   begin
      --  One byte at a time must yield the same token stream as a big buffer.
      Lex_All (Data, 1, K1, C1);
      Lex_All (Data, 64, K2, C2);
      Assert (C1 = C2 and then C1 = 6, "same token count across read sizes");
      for I in 1 .. C1 loop
         Assert (K1 (I) = K2 (I), "token" & Integer'Image (I) & " matches");
      end loop;
      Assert (K1 (1) = Lx.Tok_Begin_Object and then K1 (2) = Lx.Tok_String
              and then K1 (4) = Lx.Tok_Number, "structure recognised streamed");
      --  A number spanning single-byte reads is captured whole.
      Assert (Value_At (Data, 4, Read_Cap => 1) = "123",
              "number captured across single-byte reads");
   end Test_Streaming;

   procedure Test_Malformed (T : in out Fixture) is
      pragma Unreferenced (T);
      Bad_Tok    : aliased constant Byte_Array := To_Bytes ("@");
      Lead_Zero  : aliased constant Byte_Array := To_Bytes ("01");
      No_Frac    : aliased constant Byte_Array := To_Bytes ("1.");
      No_Exp     : aliased constant Byte_Array := To_Bytes ("1e");
      Unterm     : aliased constant Byte_Array := To_Bytes ("""abc");
      Bad_Lit    : aliased constant Byte_Array := To_Bytes ("tru");
      Ctl        : aliased constant Byte_Array :=
        To_Bytes ("""a") & [1 => Byte'(16#01#)];
   begin
      Assert (Error_Id_Of (Bad_Tok) = Representation.Errors.Json_Invalid_Token,
              "invalid token");
      Assert (Error_Id_Of (Lead_Zero) = Representation.Errors.Json_Invalid_Number,
              "leading zero");
      Assert (Error_Id_Of (No_Frac) = Representation.Errors.Json_Invalid_Number,
              "missing fraction digit");
      Assert (Error_Id_Of (No_Exp) = Representation.Errors.Json_Invalid_Number,
              "missing exponent digit");
      Assert (Error_Id_Of (Unterm) = Representation.Errors.Json_Unexpected_End,
              "unterminated string");
      Assert (Error_Id_Of (Bad_Lit) = Representation.Errors.Json_Invalid_Token,
              "truncated literal");
      Assert (Error_Id_Of (Ctl) = Representation.Errors.Json_Invalid_Token,
              "unescaped control in string");
   end Test_Malformed;

   procedure Test_Limits (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array := To_Bytes ("""abcd""");
      Lim  : constant Representation.Limits.Limits :=
        (Max_String_Bytes => 3, others => <>);
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      L    : Lx.Lexer (Src'Access, 256, 256);
      Tok  : Lx.Token;
   begin
      Lx.Start (L, Lim);
      Lx.Next (L, Tok);
      Assert (Tok.Kind = Lx.Tok_Error, "over-long string errors");
      Assert (Lx.Error_Id (L) = Representation.Errors.Limit_Max_Bytes,
              "reports the byte limit");
   end Test_Limits;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Lexer: structural", Test_Structural'Access));
      Suite.Add_Test (Caller.Create ("Lexer: literals", Test_Literals'Access));
      Suite.Add_Test (Caller.Create ("Lexer: values", Test_Values'Access));
      Suite.Add_Test (Caller.Create ("Lexer: locations", Test_Locations'Access));
      Suite.Add_Test (Caller.Create ("Lexer: streaming", Test_Streaming'Access));
      Suite.Add_Test (Caller.Create ("Lexer: malformed", Test_Malformed'Access));
      Suite.Add_Test (Caller.Create ("Lexer: limits", Test_Limits'Access));
   end Add_Tests;

end Lexer_Tests;
