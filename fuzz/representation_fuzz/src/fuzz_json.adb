--  fuzz_json — a stdin-driven JSON fuzz target for an external engine (AFL++,
--  honggfuzz, or a shell loop). It slurps bytes from standard input, decodes
--  them against Strict_Limits, and canonically re-encodes on success, printing a
--  one-line verdict. The library must never raise on hostile input; if it does,
--  this target prints PANIC and exits non-zero so the fuzzer records a finding.
with Ada.Text_IO;
with Ada.Text_IO.Text_Streams;
with Ada.Command_Line;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.Limits;
with Representation.JSON.Documents;

procedure Fuzz_Json is
   package TIO renames Ada.Text_IO;

   Max : constant := 1024 * 1024;
   Buf : Byte_Array (1 .. Max);
   Len : Natural := 0;
begin
   --  Slurp stdin (bounded).
   declare
      S : constant TIO.Text_Streams.Stream_Access :=
        TIO.Text_Streams.Stream (TIO.Standard_Input);
      C : Character;
   begin
      while not TIO.End_Of_File and then Len < Max loop
         Character'Read (S, C);
         Len := Len + 1;
         Buf (Len) := Byte (Character'Pos (C));
      end loop;
   exception
      when others =>
         null;  --  EOF / read hiccup: proceed with what was read
   end;

   declare
      Data : aliased constant Byte_Array := Buf (1 .. Len);
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      Doc  : Representation.Documents.Document (4096, 262_144);
      DR   : Representation.JSON.Documents.Decode_Result;
      OutB : aliased Representation.Buffers.Buffer (262_144);
      Snk  : Representation.Buffers.Buffer_Sink (OutB'Access);
      ER   : Representation.JSON.Documents.Encode_Result;
   begin
      Representation.JSON.Documents.Decode
        (Doc, Src'Access, DR, Limits => Representation.Limits.Strict_Limits);
      if DR.Ok then
         Representation.JSON.Documents.Encode
           (Doc, Representation.Documents.Root (Doc), Snk,
            Representation.JSON.Documents.Canonical, ER);
         TIO.Put_Line ("accept " & Boolean'Image (ER.Ok));
      else
         TIO.Put_Line ("reject " & Representation.JSON.Documents.Error_Id (DR));
      end if;
   end;
exception
   when others =>
      TIO.Put_Line ("PANIC");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
end Fuzz_Json;
