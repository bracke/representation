package body Representation.Text
  with SPARK_Mode => On
is

   --  Advance the well-formed-UTF-8 state machine (Unicode 3.9, Table 3-7) by
   --  one byte. Once failed it stays failed.
   procedure Step (V : in out Validator; B : Byte) is
   begin
      if V.Has_Failed then
         return;
      end if;

      if V.Expected > 0 then
         if B >= V.Lo and then B <= V.Hi then
            V.Expected := V.Expected - 1;
            V.Lo := 16#80#;
            V.Hi := 16#BF#;
         else
            V.Has_Failed := True;
         end if;
         return;
      end if;

      --  Expecting a leading byte.
      case B is
         when 16#00# .. 16#7F# =>
            null;                       --  ASCII
         when 16#C2# .. 16#DF# =>
            V.Expected := 1; V.Lo := 16#80#; V.Hi := 16#BF#;
         when 16#E0# =>
            V.Expected := 2; V.Lo := 16#A0#; V.Hi := 16#BF#;
         when 16#E1# .. 16#EC# | 16#EE# .. 16#EF# =>
            V.Expected := 2; V.Lo := 16#80#; V.Hi := 16#BF#;
         when 16#ED# =>
            V.Expected := 2; V.Lo := 16#80#; V.Hi := 16#9F#;  --  no surrogates
         when 16#F0# =>
            V.Expected := 3; V.Lo := 16#90#; V.Hi := 16#BF#;  --  no overlong
         when 16#F1# .. 16#F3# =>
            V.Expected := 3; V.Lo := 16#80#; V.Hi := 16#BF#;
         when 16#F4# =>
            V.Expected := 3; V.Lo := 16#80#; V.Hi := 16#8F#;  --  <= U+10FFFF
         when others =>
            V.Has_Failed := True;       --  C0,C1,F5..FF, or stray continuation
      end case;
   end Step;

   function New_Validator return Validator is
      V : Validator;
   begin
      return V;
   end New_Validator;

   procedure Feed
     (V      : in out Validator;
      Data   : Byte_Array;
      Result : out Feed_Result) is
   begin
      for B of Data loop
         Step (V, B);
      end loop;
      Result := (if V.Has_Failed then Feeding_Invalid else Feeding_Ok);
   end Feed;

   function Is_Complete (V : Validator) return Boolean is
     (not V.Has_Failed and then V.Expected = 0);

   function Failed (V : Validator) return Boolean is (V.Has_Failed);

   function Valid_Utf8 (Data : Byte_Array) return Boolean is
      V : Validator;
   begin
      for B of Data loop
         Step (V, B);
         if V.Has_Failed then
            return False;
         end if;
      end loop;
      return V.Expected = 0;
   end Valid_Utf8;

   function Scalar_Count_Of (Data : Byte_Array) return Scalar_Count is
      Count : Scalar_Count := 0;
   begin
      if not Valid_Utf8 (Data) then
         return 0;
      end if;
      --  In valid UTF-8 the number of scalars is the number of non-continuation
      --  bytes (bytes outside 16#80#..16#BF#).
      for B of Data loop
         if B < 16#80# or else B >= 16#C0# then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Scalar_Count_Of;

end Representation.Text;
