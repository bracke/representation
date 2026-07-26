package body Representation.Numbers
  with SPARK_Mode => On
is

   use type Interfaces.Unsigned_64;

   function Is_Digit (C : Character) return Boolean is (C in '0' .. '9');
   function Digit_Of (C : Character) return Integer is
     (Character'Pos (C) - Character'Pos ('0'));

   --  Shared digit-grammar check on Text (D_First .. Text'Last): non-empty,
   --  all digits, and no leading zero unless the whole run is a single "0".
   function Valid_Digit_Run (Text : String; D_First : Integer) return Boolean is
   begin
      if D_First > Text'Last then
         return False;
      end if;
      for I in D_First .. Text'Last loop
         if not Is_Digit (Text (I)) then
            return False;
         end if;
      end loop;
      if Text (D_First) = '0' and then D_First < Text'Last then
         return False;  --  leading zero
      end if;
      return True;
   end Valid_Digit_Run;

   procedure Parse_Signed
     (Text    : String;
      Value   : out Signed_Value;
      Outcome : out Parse_Outcome)
   is
      Negative : constant Boolean :=
        Text'Length > 0 and then Text (Text'First) = '-';
      D_First  : constant Integer :=
        (if Negative then Text'First + 1 else Text'First);
      --  Accumulate as a non-positive magnitude so Signed_Value'First is
      --  representable.
      Acc : Signed_Value := 0;
   begin
      Value := 0;
      if not Valid_Digit_Run (Text, D_First) then
         Outcome := Number_Syntax;
         return;
      end if;
      for I in D_First .. Text'Last loop
         declare
            D : constant Signed_Value := Signed_Value (Digit_Of (Text (I)));
         begin
            if Acc < (Signed_Value'First + D) / 10 then
               Outcome := Number_Overflow;
               return;
            end if;
            Acc := Acc * 10 - D;
         end;
      end loop;
      if Negative then
         Value := Acc;
      elsif Acc = Signed_Value'First then
         Outcome := Number_Overflow;  --  +2**63 does not fit
         return;
      else
         Value := -Acc;
      end if;
      Outcome := Number_Ok;
   end Parse_Signed;

   procedure Parse_Unsigned
     (Text    : String;
      Value   : out Unsigned_Value;
      Outcome : out Parse_Outcome)
   is
      Acc : Unsigned_Value := 0;
   begin
      Value := 0;
      if not Valid_Digit_Run (Text, Text'First) then
         Outcome := Number_Syntax;
         return;
      end if;
      for I in Text'First .. Text'Last loop
         declare
            D : constant Unsigned_Value :=
              Unsigned_Value (Digit_Of (Text (I)));
         begin
            if Acc > (Unsigned_Value'Last - D) / 10 then
               Outcome := Number_Overflow;
               return;
            end if;
            Acc := Acc * 10 + D;
         end;
      end loop;
      Value := Acc;
      Outcome := Number_Ok;
   end Parse_Unsigned;

   function Image (Value : Signed_Value) return String is
      Raw : constant String := Signed_Value'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      end if;
      return Raw;
   end Image;

   function Image (Value : Unsigned_Value) return String is
      Raw : constant String := Unsigned_Value'Image (Value);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      end if;
      return Raw;
   end Image;

end Representation.Numbers;
