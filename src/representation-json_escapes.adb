package body Representation.Json_Escapes is

   subtype Nat is Natural;

   --  Decode one UTF-8 sequence starting at I (well-formed UTF-8 only).
   procedure Decode_One
     (Content : Byte_Array;
      I       : Positive;
      Length  : out Natural;
      CP      : out Natural;
      Valid   : out Boolean)
   is
      B0 : constant Byte := Content (I);
      function C (K : Natural) return Byte is (Content (I + K));
      function Cont (K : Natural; Lo, Hi : Byte) return Boolean is
        (I + K <= Content'Last and then C (K) in Lo .. Hi);
   begin
      Valid := False; Length := 1; CP := 0;
      if B0 <= 16#7F# then
         CP := Nat (B0); Length := 1; Valid := True;
      elsif B0 in 16#C2# .. 16#DF# then
         if Cont (1, 16#80#, 16#BF#) then
            CP := (Nat (B0) - 16#C0#) * 64 + (Nat (C (1)) - 16#80#);
            Length := 2; Valid := True;
         end if;
      elsif B0 = 16#E0# then
         if Cont (1, 16#A0#, 16#BF#) and then Cont (2, 16#80#, 16#BF#) then
            CP := (Nat (B0) - 16#E0#) * 4096 + (Nat (C (1)) - 16#80#) * 64
              + (Nat (C (2)) - 16#80#);
            Length := 3; Valid := True;
         end if;
      elsif B0 in 16#E1# .. 16#EC# | 16#EE# .. 16#EF# then
         if Cont (1, 16#80#, 16#BF#) and then Cont (2, 16#80#, 16#BF#) then
            CP := (Nat (B0) - 16#E0#) * 4096 + (Nat (C (1)) - 16#80#) * 64
              + (Nat (C (2)) - 16#80#);
            Length := 3; Valid := True;
         end if;
      elsif B0 = 16#ED# then
         if Cont (1, 16#80#, 16#9F#) and then Cont (2, 16#80#, 16#BF#) then
            CP := (Nat (B0) - 16#E0#) * 4096 + (Nat (C (1)) - 16#80#) * 64
              + (Nat (C (2)) - 16#80#);
            Length := 3; Valid := True;
         end if;
      elsif B0 = 16#F0# then
         if Cont (1, 16#90#, 16#BF#) and then Cont (2, 16#80#, 16#BF#)
           and then Cont (3, 16#80#, 16#BF#)
         then
            CP := (Nat (B0) - 16#F0#) * 262144 + (Nat (C (1)) - 16#80#) * 4096
              + (Nat (C (2)) - 16#80#) * 64 + (Nat (C (3)) - 16#80#);
            Length := 4; Valid := True;
         end if;
      elsif B0 in 16#F1# .. 16#F3# then
         if Cont (1, 16#80#, 16#BF#) and then Cont (2, 16#80#, 16#BF#)
           and then Cont (3, 16#80#, 16#BF#)
         then
            CP := (Nat (B0) - 16#F0#) * 262144 + (Nat (C (1)) - 16#80#) * 4096
              + (Nat (C (2)) - 16#80#) * 64 + (Nat (C (3)) - 16#80#);
            Length := 4; Valid := True;
         end if;
      elsif B0 = 16#F4# then
         if Cont (1, 16#80#, 16#8F#) and then Cont (2, 16#80#, 16#BF#)
           and then Cont (3, 16#80#, 16#BF#)
         then
            CP := (Nat (B0) - 16#F0#) * 262144 + (Nat (C (1)) - 16#80#) * 4096
              + (Nat (C (2)) - 16#80#) * 64 + (Nat (C (3)) - 16#80#);
            Length := 4; Valid := True;
         end if;
      end if;
   end Decode_One;

   function Hex_Value (B : Byte) return Integer is
   begin
      case B is
         when Character'Pos ('0') .. Character'Pos ('9') =>
            return Nat (B) - Character'Pos ('0');
         when Character'Pos ('a') .. Character'Pos ('f') =>
            return Nat (B) - Character'Pos ('a') + 10;
         when Character'Pos ('A') .. Character'Pos ('F') =>
            return Nat (B) - Character'Pos ('A') + 10;
         when others =>
            return -1;
      end case;
   end Hex_Value;

   Hex_Digits : constant String := "0123456789abcdef";

   procedure Decode
     (Content : Byte_Array;
      Out_Buf : in out Byte_Array;
      Last    : out Natural;
      Outcome : out Escape_Outcome)
   is
      Overflowed : Boolean := False;
      Pos        : Natural := Content'First;

      procedure Put (B : Byte) is
      begin
         if Last >= Out_Buf'Last then
            Overflowed := True;
         else
            Last := Last + 1;
            Out_Buf (Last) := B;
         end if;
      end Put;

      procedure Emit (CP : Natural) is
      begin
         if CP <= 16#7F# then
            Put (Byte (CP));
         elsif CP <= 16#7FF# then
            Put (Byte (16#C0# + CP / 64));
            Put (Byte (16#80# + CP mod 64));
         elsif CP <= 16#FFFF# then
            Put (Byte (16#E0# + CP / 4096));
            Put (Byte (16#80# + (CP / 64) mod 64));
            Put (Byte (16#80# + CP mod 64));
         else
            Put (Byte (16#F0# + CP / 262144));
            Put (Byte (16#80# + (CP / 4096) mod 64));
            Put (Byte (16#80# + (CP / 64) mod 64));
            Put (Byte (16#80# + CP mod 64));
         end if;
      end Emit;

      --  Read \uXXXX at Pos (Pos points just past the 'u'); returns -1 on bad.
      function Read_Hex4 return Integer is
         V : Integer := 0;
      begin
         if Pos + 3 > Content'Last then
            return -1;
         end if;
         for K in 0 .. 3 loop
            declare
               D : constant Integer := Hex_Value (Content (Pos + K));
            begin
               if D < 0 then
                  return -1;
               end if;
               V := V * 16 + D;
            end;
         end loop;
         Pos := Pos + 4;
         return V;
      end Read_Hex4;
   begin
      Last := Out_Buf'First - 1;
      Outcome := Escape_Ok;
      while Pos <= Content'Last loop
         if Content (Pos) = Character'Pos ('\') then
            if Pos = Content'Last then
               Outcome := Escape_Invalid; return;
            end if;
            Pos := Pos + 1;
            declare
               E : constant Byte := Content (Pos);
            begin
               Pos := Pos + 1;
               case E is
                  when Character'Pos ('"')  => Emit (16#22#);
                  when Character'Pos ('\')  => Emit (16#5C#);
                  when Character'Pos ('/')  => Emit (16#2F#);
                  when Character'Pos ('b')  => Emit (16#08#);
                  when Character'Pos ('f')  => Emit (16#0C#);
                  when Character'Pos ('n')  => Emit (16#0A#);
                  when Character'Pos ('r')  => Emit (16#0D#);
                  when Character'Pos ('t')  => Emit (16#09#);
                  when Character'Pos ('u')  =>
                     declare
                        CU : constant Integer := Read_Hex4;
                     begin
                        if CU < 0 then
                           Outcome := Escape_Invalid; return;
                        elsif CU in 16#D800# .. 16#DBFF# then
                           --  high surrogate: must be followed by \uLOW
                           if Pos + 1 > Content'Last
                             or else Content (Pos) /= Character'Pos ('\')
                             or else Content (Pos + 1) /= Character'Pos ('u')
                           then
                              Outcome := Escape_Invalid; return;
                           end if;
                           Pos := Pos + 2;
                           declare
                              Low : constant Integer := Read_Hex4;
                           begin
                              if Low not in 16#DC00# .. 16#DFFF# then
                                 Outcome := Escape_Invalid; return;
                              end if;
                              Emit (16#10000#
                                + (CU - 16#D800#) * 16#400#
                                + (Low - 16#DC00#));
                           end;
                        elsif CU in 16#DC00# .. 16#DFFF# then
                           Outcome := Escape_Invalid; return;  --  lone low
                        else
                           Emit (CU);
                        end if;
                     end;
                  when others =>
                     Outcome := Escape_Invalid; return;
               end case;
            end;
         elsif Content (Pos) < 16#20# then
            Outcome := Escape_Invalid; return;  --  unescaped control
         else
            declare
               Length : Natural;
               CP     : Natural;
               Valid  : Boolean;
            begin
               Decode_One (Content, Pos, Length, CP, Valid);
               if not Valid then
                  Outcome := Escape_Invalid; return;
               end if;
               for K in 0 .. Length - 1 loop
                  Put (Content (Pos + K));
               end loop;
               Pos := Pos + Length;
            end;
         end if;
         if Overflowed then
            Outcome := Escape_Overflow; return;
         end if;
      end loop;
   end Decode;

   procedure Encode
     (Text    : Byte_Array;
      Mode    : Escape_Mode;
      Out_Buf : in out Byte_Array;
      Last    : out Natural;
      Outcome : out Escape_Outcome)
   is
      Overflowed : Boolean := False;
      Pos        : Natural := Text'First;

      procedure Put (B : Byte) is
      begin
         if Last >= Out_Buf'Last then
            Overflowed := True;
         else
            Last := Last + 1;
            Out_Buf (Last) := B;
         end if;
      end Put;

      procedure Put_Char (C : Character) is
      begin
         Put (Byte (Character'Pos (C)));
      end Put_Char;

      procedure Put_U (CU : Natural) is
      begin
         Put_Char ('\'); Put_Char ('u');
         Put_Char (Hex_Digits ((CU / 4096) mod 16 + 1));
         Put_Char (Hex_Digits ((CU / 256) mod 16 + 1));
         Put_Char (Hex_Digits ((CU / 16) mod 16 + 1));
         Put_Char (Hex_Digits (CU mod 16 + 1));
      end Put_U;

      procedure Put_Escaped_Scalar (CP : Natural) is
      begin
         if CP <= 16#FFFF# then
            Put_U (CP);
         else
            declare
               V : constant Natural := CP - 16#10000#;
            begin
               Put_U (16#D800# + V / 16#400#);
               Put_U (16#DC00# + V mod 16#400#);
            end;
         end if;
      end Put_Escaped_Scalar;
   begin
      Last := Out_Buf'First - 1;
      Outcome := Escape_Ok;
      while Pos <= Text'Last loop
         declare
            Length : Natural;
            CP     : Natural;
            Valid  : Boolean;
         begin
            Decode_One (Text, Pos, Length, CP, Valid);
            if not Valid then
               Outcome := Escape_Invalid; return;
            end if;
            case CP is
               when 16#22# => Put_Char ('\'); Put_Char ('"');
               when 16#5C# => Put_Char ('\'); Put_Char ('\');
               when 16#08# => Put_Char ('\'); Put_Char ('b');
               when 16#0C# => Put_Char ('\'); Put_Char ('f');
               when 16#0A# => Put_Char ('\'); Put_Char ('n');
               when 16#0D# => Put_Char ('\'); Put_Char ('r');
               when 16#09# => Put_Char ('\'); Put_Char ('t');
               when others =>
                  if CP < 16#20# then
                     Put_U (CP);
                  elsif Mode = Ascii_Only and then CP > 16#7F# then
                     Put_Escaped_Scalar (CP);
                  else
                     for K in 0 .. Length - 1 loop
                        Put (Text (Pos + K));
                     end loop;
                  end if;
            end case;
            Pos := Pos + Length;
         end;
         if Overflowed then
            Outcome := Escape_Overflow; return;
         end if;
      end loop;
   end Encode;

end Representation.Json_Escapes;
