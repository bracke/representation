with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;              use Representation;
with Representation.Json_Escapes;

package body Escapes_Tests is

   package JE renames Representation.Json_Escapes;
   use type JE.Escape_Outcome;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   --  UTF-8 byte sequences for reference code points.
   E_Acute : constant Byte_Array := (16#C3#, 16#A9#);              --  U+00E9
   Euro    : constant Byte_Array := (16#E2#, 16#82#, 16#AC#);      --  U+20AC
   Grin    : constant Byte_Array := (16#F0#, 16#9F#, 16#98#, 16#80#); --  U+1F600

   function Decodes_To (Input, Expect : Byte_Array) return Boolean is
      Buf  : Byte_Array (1 .. 256);
      Last : Natural;
      O    : JE.Escape_Outcome;
   begin
      JE.Decode (Input, Buf, Last, O);
      return O = JE.Escape_Ok and then Last = Expect'Length
        and then Buf (1 .. Last) = Expect;
   end Decodes_To;

   function Decode_Fails (Input : Byte_Array) return Boolean is
      Buf  : Byte_Array (1 .. 256);
      Last : Natural;
      O    : JE.Escape_Outcome;
   begin
      JE.Decode (Input, Buf, Last, O);
      return O = JE.Escape_Invalid;
   end Decode_Fails;

   function Encodes_To
     (Input : Byte_Array; Mode : JE.Escape_Mode; Expect : Byte_Array)
      return Boolean
   is
      Buf  : Byte_Array (1 .. 256);
      Last : Natural;
      O    : JE.Escape_Outcome;
   begin
      JE.Encode (Input, Mode, Buf, Last, O);
      return O = JE.Escape_Ok and then Last = Expect'Length
        and then Buf (1 .. Last) = Expect;
   end Encodes_To;

   procedure Test_Decode_Simple (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Decodes_To (To_Bytes ("\"""), To_Bytes ("""")), "escaped quote");
      Assert (Decodes_To (To_Bytes ("\\"), To_Bytes ("\")), "escaped backslash");
      Assert (Decodes_To (To_Bytes ("\n"), (1 => 16#0A#)), "newline");
      Assert (Decodes_To (To_Bytes ("\t"), (1 => 16#09#)), "tab");
      Assert (Decodes_To (To_Bytes ("a\/b"), To_Bytes ("a/b")), "escaped slash");
   end Test_Decode_Simple;

   procedure Test_Decode_Unicode (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Decodes_To (To_Bytes ("A"), To_Bytes ("A")), "BMP ASCII");
      Assert (Decodes_To (To_Bytes ("\u00e9"), E_Acute), "U+00E9 -> UTF-8");
      Assert (Decodes_To (To_Bytes ("\u20AC"), Euro),
              "U+20AC (uppercase hex) -> UTF-8");
      Assert (Decodes_To (To_Bytes ("a") & E_Acute, To_Bytes ("a") & E_Acute),
              "literal UTF-8 passes through");
   end Test_Decode_Unicode;

   procedure Test_Decode_Surrogates (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Decodes_To (To_Bytes ("\ud83d\ude00"), Grin),
              "surrogate pair -> U+1F600");
   end Test_Decode_Surrogates;

   procedure Test_Decode_Rejects (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Decode_Fails (To_Bytes ("\ud83d")), "lone high surrogate");
      Assert (Decode_Fails (To_Bytes ("\udc00")), "lone low surrogate");
      Assert (Decode_Fails (To_Bytes ("\ud83dX")), "high not followed by low");
      Assert (Decode_Fails (To_Bytes ("\ud83dA")),
              "high followed by non-surrogate");
      Assert (Decode_Fails (To_Bytes ("\x")), "unknown escape");
      Assert (Decode_Fails (To_Bytes ("\u12")), "truncated \u");
      Assert (Decode_Fails (To_Bytes ("\uZZZZ")), "non-hex \u");
      Assert (Decode_Fails ((1 => 16#01#)), "unescaped control char");
      Assert (Decode_Fails ((1 => 16#C3#)), "invalid UTF-8 literal");
   end Test_Decode_Rejects;

   procedure Test_Encode (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Encodes_To (To_Bytes (""""), JE.Minimal, To_Bytes ("\""")),
              "quote escaped");
      Assert (Encodes_To (To_Bytes ("\"), JE.Minimal, To_Bytes ("\\")),
              "backslash escaped");
      Assert (Encodes_To ((1 => 16#0A#), JE.Minimal, To_Bytes ("\n")),
              "newline escaped");
      Assert (Encodes_To ((1 => 16#01#), JE.Minimal, To_Bytes ("\u0001")),
              "control -> \\u");
      Assert (Encodes_To (To_Bytes ("abc"), JE.Minimal, To_Bytes ("abc")),
              "plain ascii unchanged");
      Assert (Encodes_To (E_Acute, JE.Minimal, E_Acute),
              "minimal leaves UTF-8 literal");
      Assert (Encodes_To (E_Acute, JE.Ascii_Only, To_Bytes ("\u00e9")),
              "ascii-only escapes non-ascii");
      Assert (Encodes_To (Grin, JE.Ascii_Only, To_Bytes ("\ud83d\ude00")),
              "ascii-only emits a surrogate pair");
   end Test_Encode;

   procedure Test_Roundtrip (T : in out Fixture) is
      pragma Unreferenced (T);
      Original : constant Byte_Array :=
        To_Bytes ("a") & E_Acute & Euro & Grin & To_Bytes ("z");
      Enc      : Byte_Array (1 .. 256);
      Enc_Last : Natural;
      Dec      : Byte_Array (1 .. 256);
      Dec_Last : Natural;
      O        : JE.Escape_Outcome;
   begin
      JE.Encode (Original, JE.Ascii_Only, Enc, Enc_Last, O);
      Assert (O = JE.Escape_Ok, "encode ok");
      JE.Decode (Enc (1 .. Enc_Last), Dec, Dec_Last, O);
      Assert (O = JE.Escape_Ok, "decode ok");
      Assert (Dec (1 .. Dec_Last) = Original, "encode/decode round-trips");
   end Test_Roundtrip;

   procedure Test_Overflow (T : in out Fixture) is
      pragma Unreferenced (T);
      Small : Byte_Array (1 .. 2);
      Last  : Natural;
      O     : JE.Escape_Outcome;
   begin
      --  "€" decodes to 3 bytes; a 2-byte buffer overflows.
      JE.Decode (Euro, Small, Last, O);
      Assert (O = JE.Escape_Overflow, "bounded output reports overflow");
   end Test_Overflow;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Escapes: decode simple", Test_Decode_Simple'Access));
      Suite.Add_Test
        (Caller.Create ("Escapes: decode unicode", Test_Decode_Unicode'Access));
      Suite.Add_Test
        (Caller.Create ("Escapes: decode surrogates",
         Test_Decode_Surrogates'Access));
      Suite.Add_Test
        (Caller.Create ("Escapes: decode rejects", Test_Decode_Rejects'Access));
      Suite.Add_Test
        (Caller.Create ("Escapes: encode", Test_Encode'Access));
      Suite.Add_Test
        (Caller.Create ("Escapes: round-trip", Test_Roundtrip'Access));
      Suite.Add_Test
        (Caller.Create ("Escapes: overflow", Test_Overflow'Access));
   end Add_Tests;

end Escapes_Tests;
