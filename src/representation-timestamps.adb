package body Representation.Timestamps is

   --  Exact proleptic-Gregorian day counts (Howard Hinnant's algorithms),
   --  days relative to 1970-01-01.
   function Days_From_Civil
     (Y : Long_Long_Integer; M : Integer; D : Integer) return Long_Long_Integer
   is
      Yy  : constant Long_Long_Integer := Y - (if M <= 2 then 1 else 0);
      Era : constant Long_Long_Integer :=
        (if Yy >= 0 then Yy else Yy - 399) / 400;
      Yoe : constant Long_Long_Integer := Yy - Era * 400;
      Doy : constant Long_Long_Integer :=
        (153 * (Long_Long_Integer (M) + (if M > 2 then -3 else 9)) + 2) / 5
        + Long_Long_Integer (D) - 1;
      Doe : constant Long_Long_Integer :=
        Yoe * 365 + Yoe / 4 - Yoe / 100 + Doy;
   begin
      return Era * 146097 + Doe - 719468;
   end Days_From_Civil;

   procedure Civil_From_Days
     (Z0 : Long_Long_Integer;
      Y  : out Long_Long_Integer;
      M  : out Integer;
      D  : out Integer)
   is
      Z   : constant Long_Long_Integer := Z0 + 719468;
      Era : constant Long_Long_Integer :=
        (if Z >= 0 then Z else Z - 146096) / 146097;
      Doe : constant Long_Long_Integer := Z - Era * 146097;
      Yoe : constant Long_Long_Integer :=
        (Doe - Doe / 1460 + Doe / 36524 - Doe / 146096) / 365;
      Yy  : constant Long_Long_Integer := Yoe + Era * 400;
      Doy : constant Long_Long_Integer :=
        Doe - (365 * Yoe + Yoe / 4 - Yoe / 100);
      Mp  : constant Long_Long_Integer := (5 * Doy + 2) / 153;
      Dd  : constant Long_Long_Integer := Doy - (153 * Mp + 2) / 5 + 1;
      Mm  : constant Long_Long_Integer := Mp + (if Mp < 10 then 3 else -9);
   begin
      Y := Yy + (if Mm <= 2 then 1 else 0);
      M := Integer (Mm);
      D := Integer (Dd);
   end Civil_From_Days;

   function Is_Leap (Y : Integer) return Boolean is
     (Y mod 4 = 0 and then (Y mod 100 /= 0 or else Y mod 400 = 0));

   function Days_In_Month (Y : Integer; M : Integer) return Integer is
     (case M is
         when 1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
         when 4 | 6 | 9 | 11              => 30,
         when 2                           => (if Is_Leap (Y) then 29 else 28),
         when others                      => 0);

   function Pad (V : Integer; Width : Positive) return String is
      S : String (1 .. Width) := [others => '0'];
      N : Integer := V;
   begin
      for I in reverse 1 .. Width loop
         S (I) := Character'Val (Character'Pos ('0') + (N mod 10));
         N := N / 10;
      end loop;
      return S;
   end Pad;

   procedure Parse
     (Text        : String;
      Value       : out Timestamp;
      Outcome     : out Parse_Outcome;
      Require_Utc : Boolean := False)
   is
      B : constant Integer := Text'First;
      L : constant Integer := Text'Last;

      function Digit (P : Integer) return Integer is
        (if P <= L and then Text (P) in '0' .. '9'
         then Character'Pos (Text (P)) - Character'Pos ('0') else -1);

      function Read_N (P : Integer; N : Integer) return Integer is
         V : Integer := 0;
      begin
         for K in 0 .. N - 1 loop
            declare
               Dg : constant Integer := Digit (P + K);
            begin
               if Dg < 0 then
                  return -1;
               end if;
               V := V * 10 + Dg;
            end;
         end loop;
         return V;
      end Read_N;

      Year, Month, Day, Hour, Minute, Second : Integer;
      Nanos       : Natural := 0;
      Pos         : Integer;
      Offset_Secs : Integer := 0;
   begin
      Value := (Instant => 0, Nanos => 0);
      Outcome := Ts_Syntax;

      if Text'Length < 20 then
         return;
      end if;

      Year := Read_N (B, 4);
      if Year < 0 or else Text (B + 4) /= '-' then return; end if;
      Month := Read_N (B + 5, 2);
      if Month < 0 or else Text (B + 7) /= '-' then return; end if;
      Day := Read_N (B + 8, 2);
      if Day < 0 or else (Text (B + 10) /= 'T' and then Text (B + 10) /= 't')
      then
         return;
      end if;
      Hour := Read_N (B + 11, 2);
      if Hour < 0 or else Text (B + 13) /= ':' then return; end if;
      Minute := Read_N (B + 14, 2);
      if Minute < 0 or else Text (B + 16) /= ':' then return; end if;
      Second := Read_N (B + 17, 2);
      if Second < 0 then return; end if;

      Pos := B + 19;

      --  Optional fractional seconds (nanosecond precision).
      if Pos <= L and then Text (Pos) = '.' then
         Pos := Pos + 1;
         if Digit (Pos) < 0 then
            return;
         end if;
         declare
            Frac_Digits : Natural := 0;
            Scale       : Natural := 100_000_000;
         begin
            while Digit (Pos) >= 0 loop
               Frac_Digits := Frac_Digits + 1;
               if Frac_Digits > 9 then
                  Outcome := Ts_Precision;
                  return;
               end if;
               Nanos := Nanos + Digit (Pos) * Scale;
               Scale := Scale / 10;
               Pos := Pos + 1;
            end loop;
         end;
      end if;

      --  Required timezone.
      if Pos > L then
         return;
      end if;
      if Text (Pos) = 'Z' or else Text (Pos) = 'z' then
         if Pos /= L then return; end if;
         Offset_Secs := 0;
      elsif Text (Pos) = '+' or else Text (Pos) = '-' then
         declare
            Neg    : constant Boolean := Text (Pos) = '-';
            OH, OM : Integer;
         begin
            if Pos + 5 /= L then return; end if;
            OH := Read_N (Pos + 1, 2);
            if OH < 0 or else Text (Pos + 3) /= ':' then return; end if;
            OM := Read_N (Pos + 4, 2);
            if OM < 0 then return; end if;
            if OH > 23 or else OM > 59 then
               Outcome := Ts_Range;
               return;
            end if;
            Offset_Secs := OH * 3600 + OM * 60;
            if Neg then
               Offset_Secs := -Offset_Secs;
            end if;
            if Require_Utc and then Offset_Secs /= 0 then
               Outcome := Ts_Requires_Utc;
               return;
            end if;
         end;
      else
         return;
      end if;

      --  Range-validate civil fields (SS = 60 leap seconds are rejected).
      if Month < 1 or else Month > 12
        or else Hour > 23 or else Minute > 59 or else Second > 59
        or else Day < 1 or else Day > Days_In_Month (Year, Month)
      then
         Outcome := Ts_Range;
         return;
      end if;

      declare
         Days : constant Long_Long_Integer :=
           Days_From_Civil (Long_Long_Integer (Year), Month, Day);
         Local : constant Long_Long_Integer :=
           Days * 86_400
           + Long_Long_Integer (Hour) * 3_600
           + Long_Long_Integer (Minute) * 60
           + Long_Long_Integer (Second);
      begin
         Value.Instant := Local - Long_Long_Integer (Offset_Secs);
         Value.Nanos := Nanos;
         Outcome := Ts_Ok;
      end;
   end Parse;

   function Canonical (T : Timestamp) return String is
      Day_Secs : constant Long_Long_Integer := T.Instant mod 86_400;
      Days     : constant Long_Long_Integer := (T.Instant - Day_Secs) / 86_400;
      Y        : Long_Long_Integer;
      M, D     : Integer;
      H        : constant Integer := Integer (Day_Secs / 3_600);
      Mi       : constant Integer := Integer ((Day_Secs mod 3_600) / 60);
      S        : constant Integer := Integer (Day_Secs mod 60);

      function Year_Image (Yr : Long_Long_Integer) return String is
        (if Yr in 0 .. 9999 then Pad (Integer (Yr), 4)
         else Long_Long_Integer'Image (Yr));

      function Fraction return String is
         F : String (1 .. 9);
         Last : Natural := 9;
      begin
         if T.Nanos = 0 then
            return "";
         end if;
         F := Pad (T.Nanos, 9);
         while Last > 1 and then F (Last) = '0' loop
            Last := Last - 1;
         end loop;
         return "." & F (1 .. Last);
      end Fraction;
   begin
      Civil_From_Days (Days, Y, M, D);
      return Year_Image (Y) & "-" & Pad (M, 2) & "-" & Pad (D, 2)
        & "T" & Pad (H, 2) & ":" & Pad (Mi, 2) & ":" & Pad (S, 2)
        & Fraction & "Z";
   end Canonical;

   function Unix_Seconds (T : Timestamp) return Long_Long_Integer is
     (T.Instant);

   function Nanoseconds (T : Timestamp) return Natural is (T.Nanos);

end Representation.Timestamps;
