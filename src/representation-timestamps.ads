--  Representation.Timestamps — the V1 timestamp profile (§7.5). Input is an
--  RFC 3339 date-time with a required timezone; the value is stored as a UTC
--  instant (seconds since 1970-01-01T00:00:00Z plus a nanosecond part) using
--  exact proleptic-Gregorian calendar arithmetic, so offsets normalize
--  correctly across day/month/year boundaries. Canonical output is UTC with a
--  trailing 'Z', deterministic, locale-independent, and carries fractional
--  seconds only when non-zero. Leap seconds (SS = 60) are not represented and
--  are rejected as out of range.
package Representation.Timestamps
  with Preelaborate
is

   type Timestamp is private;

   type Parse_Outcome is
     (Ts_Ok,
      Ts_Syntax,        --  malformed shape
      Ts_Range,         --  a field is out of range (incl. SS = 60)
      Ts_Requires_Utc,  --  a non-UTC offset where UTC was required
      Ts_Precision);    --  more than nanosecond fractional precision

   --  A timezone (Z/z or (+|-)HH:MM) is required. With Require_Utc, only Z or
   --  +00:00 / -00:00 is accepted.
   procedure Parse
     (Text        : String;
      Value       : out Timestamp;
      Outcome     : out Parse_Outcome;
      Require_Utc : Boolean := False);

   --  Canonical UTC render, e.g. "2026-07-26T14:30:00Z" or
   --  "2026-07-26T14:30:00.5Z". Fractional seconds appear only when non-zero,
   --  with trailing fractional zeros removed. Deterministic.
   function Canonical (T : Timestamp) return String;

   function Unix_Seconds (T : Timestamp) return Long_Long_Integer;
   function Nanoseconds (T : Timestamp) return Natural;

private

   type Timestamp is record
      Instant : Long_Long_Integer := 0;   --  UTC seconds since the epoch
      Nanos   : Natural           := 0;   --  0 .. 999_999_999
   end record;

end Representation.Timestamps;
