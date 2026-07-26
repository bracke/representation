package body Representation.Decimals is

   Max_Raw : constant := 4096;      --  cap on raw significand digits scanned

   function Is_Ascii_Digit (C : Character) return Boolean is (C in '0' .. '9');

   procedure Parse
     (Text    : String;
      Value   : out Decimal;
      Outcome : out Parse_Outcome)
   is
      I          : Integer := Text'First;
      Negative   : Boolean := False;
      Raw        : String (1 .. Max_Raw);
      Raw_Len    : Natural := 0;
      Frac_Count : Natural := 0;
      Exp_Signed : Long_Long_Integer := 0;

      procedure Add_Digit (C : Character; Ok : out Boolean) is
      begin
         if Raw_Len >= Max_Raw then
            Ok := False;
         else
            Raw_Len := Raw_Len + 1;
            Raw (Raw_Len) := C;
            Ok := True;
         end if;
      end Add_Digit;
   begin
      Value := Zero;
      Outcome := Decimal_Syntax;

      if Text'Length = 0 then
         return;
      end if;

      if Text (I) = '-' then
         Negative := True;
         I := I + 1;
      end if;

      --  Integer part: 0 or [1-9][0-9]*.
      if I > Text'Last or else not Is_Ascii_Digit (Text (I)) then
         return;
      end if;
      declare
         Int_First : constant Integer := I;
      begin
         while I <= Text'Last and then Is_Ascii_Digit (Text (I)) loop
            declare
               Ok : Boolean;
            begin
               Add_Digit (Text (I), Ok);
               if not Ok then
                  Outcome := Decimal_Too_Many_Digits;
                  return;
               end if;
            end;
            I := I + 1;
         end loop;
         if Text (Int_First) = '0' and then I - Int_First > 1 then
            return;  --  leading zero
         end if;
      end;

      --  Fraction: .[0-9]+.
      if I <= Text'Last and then Text (I) = '.' then
         I := I + 1;
         if I > Text'Last or else not Is_Ascii_Digit (Text (I)) then
            return;
         end if;
         while I <= Text'Last and then Is_Ascii_Digit (Text (I)) loop
            declare
               Ok : Boolean;
            begin
               Add_Digit (Text (I), Ok);
               if not Ok then
                  Outcome := Decimal_Too_Many_Digits;
                  return;
               end if;
            end;
            Frac_Count := Frac_Count + 1;
            I := I + 1;
         end loop;
      end if;

      --  Exponent: [eE][+-]?[0-9]+.
      if I <= Text'Last
        and then (Text (I) = 'e' or else Text (I) = 'E')
      then
         I := I + 1;
         declare
            Neg_Exp : Boolean := False;
            Acc     : Long_Long_Integer := 0;
         begin
            if I <= Text'Last
              and then (Text (I) = '+' or else Text (I) = '-')
            then
               Neg_Exp := Text (I) = '-';
               I := I + 1;
            end if;
            if I > Text'Last or else not Is_Ascii_Digit (Text (I)) then
               return;
            end if;
            while I <= Text'Last and then Is_Ascii_Digit (Text (I)) loop
               if Acc <= 2_000_000 then
                  Acc := Acc * 10
                    + Long_Long_Integer
                        (Character'Pos (Text (I)) - Character'Pos ('0'));
               else
                  Acc := 3_000_000;  --  clamp; range check will reject
               end if;
               I := I + 1;
            end loop;
            Exp_Signed := (if Neg_Exp then -Acc else Acc);
         end;
      end if;

      --  Trailing junk.
      if I <= Text'Last then
         return;
      end if;

      --  Normalize.
      declare
         First_Sig : Natural := 1;
         Last_Sig  : Natural := Raw_Len;
         Base_Exp  : Long_Long_Integer :=
           Exp_Signed - Long_Long_Integer (Frac_Count);
      begin
         while First_Sig < Last_Sig and then Raw (First_Sig) = '0' loop
            First_Sig := First_Sig + 1;
         end loop;

         if First_Sig = Last_Sig and then Raw (First_Sig) = '0' then
            Value := Zero;          --  all zeros, including "-0"
            Outcome := Decimal_Ok;
            return;
         end if;

         while Last_Sig > First_Sig and then Raw (Last_Sig) = '0' loop
            Last_Sig := Last_Sig - 1;
            Base_Exp := Base_Exp + 1;
         end loop;

         declare
            Sig_Len : constant Natural := Last_Sig - First_Sig + 1;
         begin
            if Sig_Len > Max_Significant_Digits then
               Outcome := Decimal_Too_Many_Digits;
               return;
            end if;
            if Base_Exp < Long_Long_Integer (Exponent_Value'First)
              or else Base_Exp > Long_Long_Integer (Exponent_Value'Last)
            then
               Outcome := Decimal_Exponent_Range;
               return;
            end if;
            Value.Sign := (if Negative then Neg else Nonneg);
            Value.Len := Sig_Len;
            Value.Coef := [others => '0'];
            Value.Coef (1 .. Sig_Len) := Raw (First_Sig .. Last_Sig);
            Value.Exp := Exponent_Value (Base_Exp);
            Outcome := Decimal_Ok;
         end;
      end;
   end Parse;

   function Is_Zero (D : Decimal) return Boolean is
     (D.Len = 1 and then D.Coef (1) = '0');

   function Is_Negative (D : Decimal) return Boolean is
     (D.Sign = Neg and then not Is_Zero (D));

   function Significand (D : Decimal) return String is (D.Coef (1 .. D.Len));

   function Exponent (D : Decimal) return Exponent_Value is (D.Exp);

   function Trim (S : String) return String is
     (if S'Length > 0 and then S (S'First) = ' '
      then S (S'First + 1 .. S'Last) else S);

   function Image (D : Decimal) return String is
   begin
      if Is_Zero (D) then
         return "0";
      end if;
      declare
         Sig      : constant String := D.Coef (1 .. D.Len);
         Adj      : constant Long_Long_Integer :=
           Long_Long_Integer (D.Exp) + Long_Long_Integer (D.Len) - 1;
         Sign_Str : constant String := (if D.Sign = Neg then "-" else "");
         Mant     : constant String :=
           (if D.Len = 1 then Sig
            else Sig (Sig'First) & "." & Sig (Sig'First + 1 .. Sig'Last));
      begin
         return Sign_Str & Mant & "E" & Trim (Long_Long_Integer'Image (Adj));
      end;
   end Image;

end Representation.Decimals;
