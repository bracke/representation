with Representation.Errors;
with Representation.Inputs; use Representation.Inputs;

package body Representation.JSON.Lexer is

   function Pos_Of (C : Character) return Byte is (Byte (Character'Pos (C)));

   procedure Set_Error (L : in out Lexer; Id : String) is
      N : constant Natural := (if Id'Length > 64 then 64 else Id'Length);
   begin
      L.Err := [others => ' '];
      L.Err (1 .. N) := Id (Id'First .. Id'First + N - 1);
      L.Err_Len := N;
   end Set_Error;

   procedure Fail (L : in out Lexer; Tok : in out Token; Id : String) is
   begin
      Set_Error (L, Id);
      Tok.Kind := Tok_Error;
   end Fail;

   --  Ensure at least one unconsumed byte is buffered; refill from the source.
   function Ensure (L : in out Lexer) return Boolean is
   begin
      while L.Buf_Pos > L.Buf_Len loop
         if L.At_Eof or else L.Failed then
            return False;
         end if;
         declare
            Last : Natural;
            St   : Read_Status;
         begin
            L.Source.Read (L.Buf, Last, St);
            if St = Read_Failed then
               L.Failed := True;
               return False;
            elsif Last >= L.Buf'First then
               L.Buf_Len := Last;
               L.Buf_Pos := L.Buf'First;
            else
               L.At_Eof := True;   --  Read_End, or a source that yielded nothing
               return False;
            end if;
         end;
      end loop;
      return True;
   end Ensure;

   function Peek (L : in out Lexer; B : out Byte) return Boolean is
   begin
      if Ensure (L) then
         B := L.Buf (L.Buf_Pos);
         return True;
      end if;
      B := 0;
      return False;
   end Peek;

   procedure Advance (L : in out Lexer) is
      B : constant Byte := L.Buf (L.Buf_Pos);
   begin
      L.Buf_Pos := L.Buf_Pos + 1;
      L.Offset := L.Offset + 1;
      if B = 16#0A# then
         L.Line := L.Line + 1;
         L.Column := 1;
      elsif B in 16#80# .. 16#BF# then
         null;  --  UTF-8 continuation byte: same character column
      else
         L.Column := L.Column + 1;
      end if;
   end Advance;

   function Capture (L : in out Lexer; B : Byte) return Boolean is
   begin
      if L.Val_Len >= L.Val'Last then
         Set_Error (L, Representation.Errors.Limit_Max_Bytes);
         return False;
      end if;
      L.Val_Len := L.Val_Len + 1;
      L.Val (L.Val_Len) := B;
      return True;
   end Capture;

   function Is_Digit (B : Byte) return Boolean is (B in 16#30# .. 16#39#);

   procedure Scan_String (L : in out Lexer; Tok : in out Token) is
      B : Byte;
   begin
      Advance (L);  --  opening quote
      loop
         if not Peek (L, B) then
            Fail (L, Tok, Representation.Errors.Json_Unexpected_End);
            return;
         end if;

         if B = Pos_Of ('"') then
            Advance (L);
            Tok.Kind := Tok_String;
            return;

         elsif B = Pos_Of ('\') then
            if not Capture (L, B) then
               Tok.Kind := Tok_Error;
               return;
            end if;
            Advance (L);
            if not Peek (L, B) then
               Fail (L, Tok, Representation.Errors.Json_Unexpected_End);
               return;
            end if;
            if not Capture (L, B) then
               Tok.Kind := Tok_Error;
               return;
            end if;
            Advance (L);

         elsif B < 16#20# then
            Fail (L, Tok, Representation.Errors.Json_Invalid_Token);
            return;

         else
            if Byte_Count (L.Val_Len) >= L.Limits.Max_String_Bytes then
               Fail (L, Tok, Representation.Errors.Limit_Max_Bytes);
               return;
            end if;
            if not Capture (L, B) then
               Tok.Kind := Tok_Error;
               return;
            end if;
            Advance (L);
         end if;
      end loop;
   end Scan_String;

   procedure Scan_Number (L : in out Lexer; Tok : in out Token) is
      B  : Byte;
      Ok : Boolean := True;

      procedure Emit is
      begin
         Ok := Capture (L, B);
         Advance (L);
      end Emit;

      First_Is_Zero : Boolean := False;
      Int_Count     : Natural := 0;
   begin
      if Peek (L, B) and then B = Pos_Of ('-') then
         Emit;
         if not Ok then
            Tok.Kind := Tok_Error;
            return;
         end if;
      end if;

      --  Integer part.
      if not (Peek (L, B) and then Is_Digit (B)) then
         Fail (L, Tok, Representation.Errors.Json_Invalid_Number);
         return;
      end if;
      First_Is_Zero := B = Pos_Of ('0');
      loop
         Emit;
         if not Ok then
            Tok.Kind := Tok_Error;
            return;
         end if;
         Int_Count := Int_Count + 1;
         exit when not (Peek (L, B) and then Is_Digit (B));
      end loop;
      if First_Is_Zero and then Int_Count > 1 then
         Fail (L, Tok, Representation.Errors.Json_Invalid_Number);
         return;
      end if;

      --  Fraction.
      if Peek (L, B) and then B = Pos_Of ('.') then
         Emit;
         if not Ok then
            Tok.Kind := Tok_Error;
            return;
         end if;
         if not (Peek (L, B) and then Is_Digit (B)) then
            Fail (L, Tok, Representation.Errors.Json_Invalid_Number);
            return;
         end if;
         while Peek (L, B) and then Is_Digit (B) loop
            Emit;
            if not Ok then
               Tok.Kind := Tok_Error;
               return;
            end if;
         end loop;
      end if;

      --  Exponent.
      if Peek (L, B) and then (B = Pos_Of ('e') or else B = Pos_Of ('E')) then
         Emit;
         if not Ok then
            Tok.Kind := Tok_Error;
            return;
         end if;
         if Peek (L, B) and then (B = Pos_Of ('+') or else B = Pos_Of ('-'))
         then
            Emit;
            if not Ok then
               Tok.Kind := Tok_Error;
               return;
            end if;
         end if;
         if not (Peek (L, B) and then Is_Digit (B)) then
            Fail (L, Tok, Representation.Errors.Json_Invalid_Number);
            return;
         end if;
         while Peek (L, B) and then Is_Digit (B) loop
            Emit;
            if not Ok then
               Tok.Kind := Tok_Error;
               return;
            end if;
         end loop;
      end if;

      Tok.Kind := Tok_Number;
   end Scan_Number;

   procedure Scan_Literal
     (L    : in out Lexer;
      Tok  : in out Token;
      Word : String;
      Kind : Token_Kind)
   is
      B : Byte;
   begin
      for C of Word loop
         if not Peek (L, B) or else B /= Pos_Of (C) then
            Fail (L, Tok, Representation.Errors.Json_Invalid_Token);
            return;
         end if;
         Advance (L);
      end loop;
      Tok.Kind := Kind;
   end Scan_Literal;

   procedure Start
     (L      : in out Lexer;
      Limits : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits) is
   begin
      L.Limits := Limits;
      L.Buf_Len := 0;
      L.Buf_Pos := 1;
      L.At_Eof := False;
      L.Failed := False;
      L.Offset := 0;
      L.Line := 1;
      L.Column := 1;
      L.Val_Len := 0;
      L.Err_Len := 0;
   end Start;

   procedure Next (L : in out Lexer; Tok : out Token) is
      B : Byte;
   begin
      L.Val_Len := 0;

      --  Skip insignificant whitespace.
      loop
         exit when not Peek (L, B);
         exit when B not in 16#20# | 16#09# | 16#0A# | 16#0D#;
         Advance (L);
      end loop;

      Tok := (Kind   => Tok_Error,
              Offset => L.Offset,
              Line   => L.Line,
              Column => L.Column,
              Length => 0);

      if L.Failed then
         Set_Error (L, Representation.Errors.Io_Source_Failure);
         return;
      end if;
      if Byte_Count (L.Offset) > L.Limits.Max_Input_Bytes then
         Set_Error (L, Representation.Errors.Limit_Max_Bytes);
         return;
      end if;
      if not Peek (L, B) then
         if L.Failed then
            Set_Error (L, Representation.Errors.Io_Source_Failure);
         else
            Tok.Kind := Tok_End_Of_Input;
         end if;
         return;
      end if;

      case B is
         when 16#7B# => Advance (L); Tok.Kind := Tok_Begin_Object;     --  {
         when 16#7D# => Advance (L); Tok.Kind := Tok_End_Object;       --  }
         when 16#5B# => Advance (L); Tok.Kind := Tok_Begin_Array;      --  [
         when 16#5D# => Advance (L); Tok.Kind := Tok_End_Array;        --  ]
         when 16#3A# => Advance (L); Tok.Kind := Tok_Name_Separator;   --  :
         when 16#2C# => Advance (L); Tok.Kind := Tok_Value_Separator;  --  ,
         when 16#22# => Scan_String (L, Tok);                          --  "
         when 16#2D# | 16#30# .. 16#39# => Scan_Number (L, Tok);       --  - 0-9
         when 16#74# => Scan_Literal (L, Tok, "true", Tok_True);
         when 16#66# => Scan_Literal (L, Tok, "false", Tok_False);
         when 16#6E# => Scan_Literal (L, Tok, "null", Tok_Null);
         when others =>
            Advance (L);
            Fail (L, Tok, Representation.Errors.Json_Invalid_Token);
      end case;

      Tok.Length := L.Val_Len;
   end Next;

   function Value (L : Lexer) return Byte_Array is (L.Val (1 .. L.Val_Len));

   function Error_Id (L : Lexer) return String is (L.Err (1 .. L.Err_Len));

end Representation.JSON.Lexer;
