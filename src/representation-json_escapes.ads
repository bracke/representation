--  Representation.Json_Escapes — JSON string escaping (§22.2). Decodes the raw
--  content between a JSON string's quotes (escapes and all) into UTF-8 bytes,
--  and encodes UTF-8 bytes into escaped JSON string content. Correctly handles
--  \uXXXX and surrogate pairs, and rejects lone/misordered surrogates, invalid
--  escapes, malformed \u, unescaped control characters, and invalid UTF-8
--  (REP-INV-004). Bounded: writes into a caller-provided buffer and reports
--  overflow rather than growing.
package Representation.Json_Escapes
  with Preelaborate
is

   type Escape_Outcome is (Escape_Ok, Escape_Invalid, Escape_Overflow);

   procedure Decode
     (Content : Byte_Array;
      Out_Buf : in out Byte_Array;
      Last    : out Natural;
      Outcome : out Escape_Outcome);

   type Escape_Mode is
     (Minimal,      --  escape only what JSON requires (", \, controls)
      Ascii_Only);  --  additionally \u-escape every non-ASCII scalar

   procedure Encode
     (Text    : Byte_Array;
      Mode    : Escape_Mode;
      Out_Buf : in out Byte_Array;
      Last    : out Natural;
      Outcome : out Escape_Outcome);

end Representation.Json_Escapes;
