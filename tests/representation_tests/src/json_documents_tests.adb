with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;                use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Errors;
with Representation.Documents;
with Representation.JSON.Documents;

package body JSON_Documents_Tests is

   package DM renames Representation.Documents;
   package JD renames Representation.JSON.Documents;
   use type DM.Node_Kind;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function To_Str (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_Str;

   --  Decode In_JSON, re-encode Root in Style, return the encoded text. Ok is
   --  the decode success flag.
   function Transcode
     (In_JSON : String; Style : JD.Encoding; Ok : out Boolean) return String
   is
      Data : aliased constant Byte_Array := To_Bytes (In_JSON);
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc  : DM.Document (256, 8192);
      DR   : JD.Decode_Result;
      Buf  : aliased Representation.Buffers.Buffer (8192);
      Snk  : Representation.Buffers.Buffer_Sink (Buf'Access);
      ER   : JD.Encode_Result;
   begin
      JD.Decode (Doc, Src'Access, DR);
      Ok := DR.Ok;
      if not DR.Ok then
         return "";
      end if;
      JD.Encode (Doc, DM.Root (Doc), Snk, Style, ER);
      return To_Str (Representation.Buffers.To_Byte_Array (Buf));
   end Transcode;

   procedure Test_Decode_Scalars (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array :=
        To_Bytes ("[true, 123, ""hi"", null]");
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc  : DM.Document (64, 512);
      DR   : JD.Decode_Result;
      Root : DM.Node_Ref;
   begin
      JD.Decode (Doc, Src'Access, DR);
      Assert (DR.Ok, "decode ok");
      Root := DM.Root (Doc);
      Assert (DM.Kind (Doc, Root) = DM.Array_Node
              and then DM.Length (Doc, Root) = 4, "array of four");
      Assert (DM.Kind (Doc, DM.Element (Doc, Root, 1)) = DM.Bool_Node
              and then DM.Bool_Value (Doc, DM.Element (Doc, Root, 1)),
              "true");
      Assert (To_Str (DM.Text (Doc, DM.Element (Doc, Root, 2))) = "123",
              "number text");
      Assert (To_Str (DM.Text (Doc, DM.Element (Doc, Root, 3))) = "hi",
              "string content");
      Assert (DM.Kind (Doc, DM.Element (Doc, Root, 4)) = DM.Null_Node, "null");
   end Test_Decode_Scalars;

   procedure Test_Decode_Structure (T : in out Fixture) is
      pragma Unreferenced (T);
      Data : aliased constant Byte_Array :=
        To_Bytes ("{""id"": 7, ""tags"": [""a"", ""b""]}");
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc  : DM.Document (64, 512);
      DR   : JD.Decode_Result;
      Root, Tags : DM.Node_Ref;
   begin
      JD.Decode (Doc, Src'Access, DR);
      Assert (DR.Ok, "decode ok");
      Root := DM.Root (Doc);
      Assert (DM.Kind (Doc, Root) = DM.Object_Node, "object");
      Assert (To_Str (DM.Text (Doc, DM.Find (Doc, Root, To_Bytes ("id")))) = "7",
              "id value");
      Tags := DM.Find (Doc, Root, To_Bytes ("tags"));
      Assert (DM.Kind (Doc, Tags) = DM.Array_Node
              and then DM.Length (Doc, Tags) = 2, "tags array");
      Assert (To_Str (DM.Text (Doc, DM.Element (Doc, Tags, 2))) = "b",
              "second tag");
   end Test_Decode_Structure;

   procedure Test_Decode_Escapes (T : in out Fixture) is
      pragma Unreferenced (T);
      --  JSON string "aA\n\"" decodes to a, A, LF, ".
      Data : aliased constant Byte_Array := To_Bytes ("""aA\n\""""");
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc  : DM.Document (16, 64);
      DR   : JD.Decode_Result;
      Expected : constant Byte_Array :=
        [Byte (Character'Pos ('a')), Byte (Character'Pos ('A')),
         16#0A#, Byte (Character'Pos ('"'))];
   begin
      JD.Decode (Doc, Src'Access, DR);
      Assert (DR.Ok, "decode ok");
      Assert (DM.Text (Doc, DM.Root (Doc)) = Expected,
              "escapes decoded to UTF-8 content");
   end Test_Decode_Escapes;

   procedure Test_Decode_Errors (T : in out Fixture) is
      pragma Unreferenced (T);

      function Err_Of (JSON : String) return String is
         Data : aliased constant Byte_Array := To_Bytes (JSON);
         Src  : aliased Representation.Inputs.Array_Source (Data'Access);
         Doc  : DM.Document (32, 256);
         DR   : JD.Decode_Result;
      begin
         JD.Decode (Doc, Src'Access, DR);
         Assert (not DR.Ok, "expected failure: " & JSON);
         return JD.Error_Id (DR);
      end Err_Of;
   begin
      Assert (Err_Of ("{""a"":1,""a"":2}")
              = Representation.Errors.Object_Duplicate_Field,
              "duplicate key");
      Assert (Err_Of ("[1,2")
              = Representation.Errors.Json_Unexpected_End,
              "unterminated array");
      Assert (Err_Of ("nul")
              = Representation.Errors.Json_Invalid_Token,
              "bad literal");
   end Test_Decode_Errors;

   procedure Test_Round_Trip (T : in out Fixture) is
      pragma Unreferenced (T);
      Ok : Boolean;
      In_JSON : constant String := "{""a"":1,""b"":[true,null]}";
      Out_JSON : constant String := Transcode (In_JSON, JD.Compact, Ok);
   begin
      Assert (Ok, "decode ok");
      Assert (Out_JSON = In_JSON, "compact round-trip is faithful: " & Out_JSON);
   end Test_Round_Trip;

   procedure Test_Encode_Styles (T : in out Fixture) is
      pragma Unreferenced (T);
      Ok1, Ok2, Ok3 : Boolean;
      Compact : constant String := Transcode ("[1, 2]", JD.Compact, Ok1);
      Pretty  : constant String := Transcode ("[1,2]", JD.Pretty, Ok2);
      Canon   : constant String :=
        Transcode ("{""b"":""y"",""a"":""x""}", JD.Canonical, Ok3);
   begin
      Assert (Ok1 and then Ok2 and then Ok3, "all decode");
      Assert (Compact = "[1,2]", "compact array: " & Compact);
      Assert (Pretty = "[" & ASCII.LF & "  1," & ASCII.LF & "  2" & ASCII.LF & "]",
              "pretty array");
      Assert (Canon = "{""a"":""x"",""b"":""y""}",
              "canonical sorts keys: " & Canon);
   end Test_Encode_Styles;

   procedure Test_Canonical_Reproducible (T : in out Fixture) is
      pragma Unreferenced (T);
      Ok1, Ok2 : Boolean;
      --  Same value, different member order and number spelling.
      A : constant String :=
        Transcode ("{""b"":1,""a"":1.0}", JD.Canonical, Ok1);
      B : constant String :=
        Transcode ("{""a"":1,""b"":1}", JD.Canonical, Ok2);
   begin
      Assert (Ok1 and then Ok2, "both decode");
      Assert (A = B, "equal values -> byte-identical canonical: " & A & " / " & B);
   end Test_Canonical_Reproducible;

   procedure Test_Canonical_Idempotent (T : in out Fixture) is
      pragma Unreferenced (T);
      Ok1, Ok2 : Boolean;
      Once  : constant String :=
        Transcode ("{""z"":[3,2,1],""a"":{""y"":1,""x"":2}}", JD.Canonical, Ok1);
      Twice : constant String := Transcode (Once, JD.Canonical, Ok2);
   begin
      Assert (Ok1 and then Ok2, "both decode");
      Assert (Once = Twice, "canonical is a fixed point: " & Once);
   end Test_Canonical_Idempotent;

   procedure Test_Canonical_Numbers (T : in out Fixture) is
      pragma Unreferenced (T);
      Ok : Boolean;
      --  Keys a..e already sorted; every number canonicalizes to plain decimal.
      In_JSON : constant String :=
        "{""a"":1500,""b"":1.5,""c"":0.015,""d"":-2,""e"":10e-1}";
      Out_JSON : constant String := Transcode (In_JSON, JD.Canonical, Ok);
   begin
      Assert (Ok, "decode ok");
      --  Integers stay integers (no scientific notation); 10e-1 folds to 1.
      Assert (Out_JSON = "{""a"":1500,""b"":1.5,""c"":0.015,""d"":-2,""e"":1}",
              "plain canonical numbers: " & Out_JSON);
   end Test_Canonical_Numbers;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("JSON docs: decode scalars", Test_Decode_Scalars'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: decode structure",
         Test_Decode_Structure'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: decode escapes", Test_Decode_Escapes'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: decode errors", Test_Decode_Errors'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: round trip", Test_Round_Trip'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: encode styles", Test_Encode_Styles'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: canonical reproducible",
         Test_Canonical_Reproducible'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: canonical idempotent",
         Test_Canonical_Idempotent'Access));
      Suite.Add_Test
        (Caller.Create ("JSON docs: canonical numbers",
         Test_Canonical_Numbers'Access));
   end Add_Tests;

end JSON_Documents_Tests;
