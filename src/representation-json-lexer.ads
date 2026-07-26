--  Representation.JSON.Lexer — a deterministic, defensive, incremental JSON
--  tokenizer (§22.1). It pulls bytes from a Representation.Inputs.Source
--  through a fixed read buffer, so the whole payload need not reside in memory,
--  and accumulates the current token's value into a bounded scratch. Every
--  token carries its start location (byte offset, line, column). Malformed
--  input, limit exhaustion, and source failures are reported as a Tok_Error
--  token with a stable machine error id; end-of-input is Tok_End_Of_Input.
--
--  String tokens expose their raw content (escapes intact, quotes stripped);
--  decoding to UTF-8 is the value/parse layer's job. Number tokens expose the
--  validated number text.
with Representation.Inputs;
with Representation.Limits;
package Representation.JSON.Lexer is

   type Token_Kind is
     (Tok_Begin_Object,     --  {
      Tok_End_Object,       --  }
      Tok_Begin_Array,      --  [
      Tok_End_Array,        --  ]
      Tok_Name_Separator,   --  :
      Tok_Value_Separator,  --  ,
      Tok_String,
      Tok_Number,
      Tok_True,
      Tok_False,
      Tok_Null,
      Tok_End_Of_Input,
      Tok_Error);

   type Token is record
      Kind   : Token_Kind   := Tok_Error;
      Offset : Byte_Offset  := 0;   --  0-based byte offset of the token start
      Line   : Line_Number  := 1;   --  1-based
      Column : Column_Number := 1;  --  1-based
      Length : Natural      := 0;   --  value length (String content / Number text)
   end record;

   --  A lexer reads from Source (which must outlive the lexer) and owns a read
   --  buffer (Read_Capacity bytes) and a token-value scratch (Value_Capacity
   --  bytes). The source is bound at construction so a stack-allocated source
   --  and its lexer can be co-scoped without accessibility gymnastics.
   type Lexer
     (Source         : not null access Representation.Inputs.Source'Class;
      Read_Capacity  : Positive;
      Value_Capacity : Positive) is limited private;

   --  (Re)initialize the lexer's scan state and select the limits to enforce.
   --  Must be called once before the first Next.
   procedure Start
     (L      : in out Lexer;
      Limits : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits);

   procedure Next (L : in out Lexer; Tok : out Token);

   --  Raw bytes of the most recent String / Number token.
   function Value (L : Lexer) return Byte_Array;

   --  Stable machine error id for the most recent Tok_Error.
   function Error_Id (L : Lexer) return String;

private

   type Lexer
     (Source         : not null access Representation.Inputs.Source'Class;
      Read_Capacity  : Positive;
      Value_Capacity : Positive) is limited
   record
      Limits    : Representation.Limits.Limits;
      Buf       : Byte_Array (1 .. Read_Capacity);
      Buf_Len   : Natural := 0;
      Buf_Pos   : Natural := 1;
      At_Eof    : Boolean := False;
      Failed    : Boolean := False;
      Offset    : Byte_Offset   := 0;
      Line      : Line_Number   := 1;
      Column    : Column_Number := 1;
      Val       : Byte_Array (1 .. Value_Capacity);
      Val_Len   : Natural := 0;
      Err       : String (1 .. 64) := [others => ' '];
      Err_Len   : Natural := 0;
   end record;

end Representation.JSON.Lexer;
