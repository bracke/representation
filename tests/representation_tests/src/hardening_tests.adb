with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Interfaces;                use Interfaces;
with Representation;            use Representation;
with Representation.Inputs;
with Representation.Outputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.Limits;
with Representation.Errors;
with Representation.JSON.Documents;

package body Hardening_Tests is

   package DM renames Representation.Documents;
   package JD renames Representation.JSON.Documents;
   package Ins renames Representation.Inputs;
   package Outs renames Representation.Outputs;
   use type Representation.Errors.Error_Category;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function To_Str (B : Byte_Array) return String is
      R : String (1 .. B'Length);
   begin
      for I in B'Range loop
         R (I - B'First + 1) := Character'Val (Natural (B (I)));
      end loop;
      return R;
   end To_Str;

   --  Decode and report whether the input was rejected (never raising).
   function Rejects_Bytes
     (Data : not null access constant Byte_Array; Strict : Boolean := False)
      return Boolean
   is
      Src : aliased Ins.Array_Source (Data);
      Doc : DM.Document (256, 8192);
      DR  : JD.Decode_Result;
      Lim : constant Representation.Limits.Limits :=
        (if Strict then Representation.Limits.Strict_Limits
         else Representation.Limits.Default_Limits);
   begin
      JD.Decode (Doc, Src'Access, DR, Limits => Lim);
      return not DR.Ok;
   end Rejects_Bytes;

   function Rejects (JSON : String; Strict : Boolean := False) return Boolean is
      Data : aliased constant Byte_Array := To_Bytes (JSON);
   begin
      return Rejects_Bytes (Data'Access, Strict);
   end Rejects;

   procedure Test_Malformed_Corpus (T : in out Fixture) is
      pragma Unreferenced (T);
      Deep : constant String := [1 .. 40 => '['] & "1" & [1 .. 40 => ']'];
   begin
      --  Structure / grammar.
      Assert (Rejects (""), "empty");
      Assert (Rejects ("{"), "open object");
      Assert (Rejects ("["), "open array");
      Assert (Rejects ("}"), "stray close");
      Assert (Rejects ("{""a""}"), "member without colon");
      Assert (Rejects ("{""a"":}"), "member without value");
      Assert (Rejects ("[1,]"), "trailing comma array");
      Assert (Rejects ("[,]"), "bare comma array");
      Assert (Rejects ("{,}"), "bare comma object");
      Assert (Rejects ("[1 2]"), "missing comma");
      Assert (Rejects ("1 2"), "two top-level values");
      Assert (Rejects ("truex"), "trailing garbage after literal");
      Assert (Rejects ("nul"), "truncated literal");
      Assert (Rejects ("@"), "invalid token");
      --  Numbers.
      Assert (Rejects ("01"), "leading zero");
      Assert (Rejects ("1."), "missing fraction");
      Assert (Rejects ("1e"), "missing exponent");
      Assert (Rejects (".5"), "missing integer part");
      Assert (Rejects ("+1"), "plus sign");
      --  Strings.
      Assert (Rejects ("""abc"), "unterminated string");
      Assert (Rejects ("""a\x"""), "invalid escape");
      Assert (Rejects ("""\ud800"""), "lone high surrogate");
      Assert (Rejects ("""\udc00"""), "lone low surrogate");
      --  Semantic.
      Assert (Rejects ("{""a"":1,""a"":2}"), "duplicate member");
      Assert (Rejects (Deep, Strict => True), "excessive nesting (Strict)");

      --  Invalid UTF-8 inside a string (bytes, not literals).
      declare
         Lone_Cont : aliased constant Byte_Array :=
           [Byte (Character'Pos ('"')), 16#80#, Byte (Character'Pos ('"'))];
         Overlong  : aliased constant Byte_Array :=
           [Byte (Character'Pos ('"')), 16#C0#, 16#80#,
            Byte (Character'Pos ('"'))];
      begin
         Assert (Rejects_Bytes (Lone_Cont'Access), "lone continuation byte");
         Assert (Rejects_Bytes (Overlong'Access), "overlong encoding");
      end;
   end Test_Malformed_Corpus;

   --  A cheap deterministic PRNG (splitmix64-style) for reproducible fuzzing.
   State : Unsigned_64 := 16#9E3779B97F4A7C15#;

   procedure Reseed (S : Unsigned_64) is
   begin
      State := S;
   end Reseed;

   function Next return Unsigned_64 is
      Z : Unsigned_64;
   begin
      State := State + 16#9E3779B97F4A7C15#;
      Z := State;
      Z := (Z xor Shift_Right (Z, 30)) * 16#BF58476D1CE4E5B9#;
      Z := (Z xor Shift_Right (Z, 27)) * 16#94D049BB133111EB#;
      return Z xor Shift_Right (Z, 31);
   end Next;

   --  Canonicalize Data; Ok reports decode+encode success. Never raises.
   function Canonicalize
     (Data : not null access constant Byte_Array; Ok : out Boolean)
      return Byte_Array
   is
      Src : aliased Ins.Array_Source (Data);
      Doc : DM.Document (256, 8192);
      DR  : JD.Decode_Result;
      Buf : aliased Representation.Buffers.Buffer (8192);
      Snk : Representation.Buffers.Buffer_Sink (Buf'Access);
      ER  : JD.Encode_Result;
   begin
      Ok := False;
      JD.Decode (Doc, Src'Access, DR, Limits => Representation.Limits.Strict_Limits);
      if not DR.Ok then
         return [1 .. 0 => 0];
      end if;
      JD.Encode (Doc, DM.Root (Doc), Snk, JD.Canonical, ER);
      Ok := ER.Ok;
      return Representation.Buffers.To_Byte_Array (Buf);
   end Canonicalize;

   Alphabet : constant String := "{}[]:,""0123456789tfn aeulsr.-+E ";

   --  A random byte string of the given length; mostly drawn from a JSON-ish
   --  alphabet, occasionally any byte, to exercise both accept and reject paths.
   function Random_Bytes (Len : Natural) return Byte_Array is
      R : Byte_Array (1 .. Len);
   begin
      for I in R'Range loop
         if (Next and 3) = 0 then
            R (I) := Byte (Next mod 256);
         else
            R (I) :=
              Byte (Character'Pos
                      (Alphabet
                         (1 + Natural
                            (Next mod Unsigned_64 (Alphabet'Length)))));
         end if;
      end loop;
      return R;
   end Random_Bytes;

   procedure Test_Fuzz_No_Crash (T : in out Fixture) is
      pragma Unreferenced (T);
      Rounds : constant := 4000;
      Valid  : Natural := 0;
   begin
      Reseed (12345);
      for R in 1 .. Rounds loop
         declare
            Len  : constant Natural := Natural (Next mod 48);
            Data : aliased constant Byte_Array := Random_Bytes (Len);
            Ok   : Boolean;
            --  The property under test: decoding never raises; it returns a
            --  verdict. (A raised exception surfaces as an AUnit error.)
            C1 : constant Byte_Array := Canonicalize (Data'Access, Ok);
         begin
               if Ok then
                  Valid := Valid + 1;
                  --  On a valid parse, canonical output is a fixed point.
                  declare
                     C1a : aliased constant Byte_Array := C1;
                     Ok2 : Boolean;
                     C2  : constant Byte_Array := Canonicalize (C1a'Access, Ok2);
                  begin
                     Assert (Ok2 and then C1 = C2,
                             "canonical is idempotent over fuzzed input");
                  end;
               end if;
         end;
      end loop;
      --  Sanity: the alphabet-biased generator produced some valid documents.
      Assert (Valid > 0, "fuzzer exercised the accept path too");
   end Test_Fuzz_No_Crash;

   procedure Test_Canonical_Properties (T : in out Fixture) is
      pragma Unreferenced (T);
      --  Two structurally-equal but differently-spelled inputs.
      A : aliased constant Byte_Array :=
        To_Bytes ("{""b"":1.0,""a"":[1,2,3],""n"":10e-1}");
      B : aliased constant Byte_Array :=
        To_Bytes ("{""a"":[1,2,3],""n"":1,""b"":1}");
      Ok1, Ok2 : Boolean;
      CA : constant Byte_Array := Canonicalize (A'Access, Ok1);
      CB : constant Byte_Array := Canonicalize (B'Access, Ok2);
   begin
      Assert (Ok1 and then Ok2, "both canonicalize");
      Assert (To_Str (CA) = To_Str (CB),
              "equal values -> identical canonical bytes: "
              & To_Str (CA) & " / " & To_Str (CB));
   end Test_Canonical_Properties;

   --  A source that delivers bytes one at a time, then fails.
   type Failing_Source
     (Data : not null access constant Byte_Array; Fail_After : Natural) is
     limited new Ins.Source with record
      Consumed : Natural := 0;
   end record;

   overriding procedure Read
     (From   : in out Failing_Source;
      Into   : out Byte_Array;
      Last   : out Natural;
      Status : out Ins.Read_Status);

   overriding procedure Read
     (From   : in out Failing_Source;
      Into   : out Byte_Array;
      Last   : out Natural;
      Status : out Ins.Read_Status) is
   begin
      if From.Consumed >= From.Fail_After then
         Last := Into'First - 1;
         Status := Ins.Read_Failed;
         return;
      end if;
      Into (Into'First) := From.Data (From.Data'First + From.Consumed);
      From.Consumed := From.Consumed + 1;
      Last := Into'First;
      Status := Ins.Read_Ok;
   end Read;

   procedure Test_Source_Failure (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array :=
        To_Bytes ("[0,1,2,3,4,5,6,7,8,9]");
      Src  : aliased Failing_Source (Data'Access, Fail_After => 6);
      Doc  : DM.Document (64, 512);
      DR   : JD.Decode_Result;
   begin
      JD.Decode (Doc, Src'Access, DR);
      Assert (not DR.Ok and then DR.Category = Representation.Errors.IO_Failure,
              "mid-stream source failure surfaces as IO_Failure, not a crash");
   end Test_Source_Failure;

   --  A sink that fails once more than Fail_After bytes have been written.
   type Failing_Sink (Fail_After : Natural) is
     limited new Outs.Sink with record
      Written : Natural := 0;
   end record;

   overriding procedure Write
     (To     : in out Failing_Sink;
      Data   : Byte_Array;
      Status : out Outs.Write_Status);

   overriding procedure Write
     (To     : in out Failing_Sink;
      Data   : Byte_Array;
      Status : out Outs.Write_Status) is
   begin
      if To.Written + Data'Length > To.Fail_After then
         Status := Outs.Write_Failed;
      else
         To.Written := To.Written + Data'Length;
         Status := Outs.Write_Ok;
      end if;
   end Write;

   procedure Test_Sink_Failure (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : DM.Document (64, 512);
      Arr : DM.Node_Ref;
      Snk : Failing_Sink (Fail_After => 4);
      ER  : JD.Encode_Result;
   begin
      Arr := DM.Add_Array (Doc);
      for I in 1 .. 10 loop
         DM.Append (Doc, Arr, DM.Add_Number (Doc, To_Bytes ("123")));
      end loop;
      JD.Encode (Doc, Arr, Snk, JD.Compact, ER);
      Assert (not ER.Ok and then ER.Category = Representation.Errors.IO_Failure,
              "sink failure surfaces without a crash");
   end Test_Sink_Failure;

   procedure Test_Concurrency (T : in out Fixture) is
      pragma Unreferenced (T);
      N        : constant := 8;
      Input    : aliased constant Byte_Array :=
        To_Bytes ("{""b"":2,""a"":[3,2,1],""c"":true}");
      Expected : constant String := "{""a"":[3,2,1],""b"":2,""c"":true}";
      Results  : array (1 .. N) of Boolean := [others => False];

      task type Worker is
         entry Go (Id : Positive);
      end Worker;

      task body Worker is
         My : Positive;
      begin
         accept Go (Id : Positive) do
            My := Id;
         end Go;
         declare
            Src : aliased Ins.Array_Source (Input'Access);
            Doc : DM.Document (128, 2048);
            DR  : JD.Decode_Result;
            Buf : aliased Representation.Buffers.Buffer (512);
            Snk : Representation.Buffers.Buffer_Sink (Buf'Access);
            ER  : JD.Encode_Result;
         begin
            JD.Decode (Doc, Src'Access, DR);
            if DR.Ok then
               JD.Encode (Doc, DM.Root (Doc), Snk, JD.Canonical, ER);
               Results (My) := ER.Ok
                 and then To_Str (Representation.Buffers.To_Byte_Array (Buf))
                          = Expected;
            end if;
         end;
      end Worker;
   begin
      --  Independent instances on separate arenas must not interfere (no hidden
      --  global state — REP-INV-010).
      declare
         Pool : array (1 .. N) of Worker;
      begin
         for I in Pool'Range loop
            Pool (I).Go (I);
         end loop;
      end;  --  block exit joins all workers

      for I in 1 .. N loop
         Assert (Results (I), "worker" & Integer'Image (I) & " decoded/encoded");
      end loop;
   end Test_Concurrency;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Hardening: malformed corpus",
         Test_Malformed_Corpus'Access));
      Suite.Add_Test
        (Caller.Create ("Hardening: fuzz no crash", Test_Fuzz_No_Crash'Access));
      Suite.Add_Test
        (Caller.Create ("Hardening: canonical properties",
         Test_Canonical_Properties'Access));
      Suite.Add_Test
        (Caller.Create ("Hardening: source failure", Test_Source_Failure'Access));
      Suite.Add_Test
        (Caller.Create ("Hardening: sink failure", Test_Sink_Failure'Access));
      Suite.Add_Test
        (Caller.Create ("Hardening: concurrency", Test_Concurrency'Access));
   end Add_Tests;

end Hardening_Tests;
