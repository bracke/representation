--  bench — a deterministic throughput smoke benchmark: decode a moderately
--  complex JSON document and re-emit it canonically, many times, over a fixed
--  arena. Reports elapsed time, throughput, and a checksum (so the work is not
--  optimized away). Not a correctness test; a coarse performance signal and a
--  guard that the hot path stays allocation-free and bounded.
with Ada.Text_IO;  use Ada.Text_IO;
with Ada.Real_Time; use Ada.Real_Time;
with Interfaces;   use Interfaces;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.JSON.Documents;

procedure Bench is

   function Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

   Input : aliased constant Byte_Array := Bytes
     ("{ ""id"": 12345, ""name"": ""widget"","
      & " ""tags"": [""alpha"", ""beta"", ""gamma""],"
      & " ""price"": 19.99, ""active"": true,"
      & " ""meta"": { ""x"": 1, ""y"": 2, ""z"": 3 },"
      & " ""nums"": [1, 2, 3, 4, 5, 6, 7, 8] }");

   Iterations : constant := 100_000;
   Checksum   : Unsigned_64 := 0;
   T0, T1     : Time;
begin
   Put_Line ("input bytes:" & Input'Length'Image);
   T0 := Clock;
   for I in 1 .. Iterations loop
      declare
         Src : aliased Representation.Inputs.Array_Source (Input'Access);
         Doc : Representation.Documents.Document (256, 4096);
         DR  : Representation.JSON.Documents.Decode_Result;
         Buf : aliased Representation.Buffers.Buffer (4096);
         Snk : Representation.Buffers.Buffer_Sink (Buf'Access);
         ER  : Representation.JSON.Documents.Encode_Result;
      begin
         Representation.JSON.Documents.Decode (Doc, Src'Access, DR);
         if DR.Ok then
            Representation.JSON.Documents.Encode
              (Doc, Representation.Documents.Root (Doc), Snk,
               Representation.JSON.Documents.Canonical, ER);
            Checksum :=
              Checksum + Unsigned_64 (Representation.Buffers.Length (Buf));
         end if;
      end;
   end loop;
   T1 := Clock;

   declare
      Elapsed : constant Long_Float := Long_Float (To_Duration (T1 - T0));
      Ops     : constant Long_Float :=
        (if Elapsed > 0.0 then Long_Float (Iterations) / Elapsed else 0.0);
   begin
      Put_Line ("iterations: " & Iterations'Image);
      Put_Line ("elapsed s:  " & Elapsed'Image);
      Put_Line ("ops/sec:    " & Long_Float'Image (Ops));
      Put_Line ("checksum:   " & Checksum'Image);
   end;
end Bench;
