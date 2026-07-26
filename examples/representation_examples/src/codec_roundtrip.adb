--  codec_roundtrip — parse JSON bytes into the document model and re-emit them
--  in canonical form (object members sorted, numbers normalized to plain
--  decimal). Demonstrates Representation.JSON.Documents on in-memory buffers;
--  the same Source/Sink abstractions stream from any transport.
with Ada.Text_IO; use Ada.Text_IO;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.JSON.Documents;

procedure Codec_Roundtrip is

   function Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

   function Str (B : Byte_Array) return String is
      R : String (1 .. B'Length);
   begin
      for I in B'Range loop
         R (I - B'First + 1) := Character'Val (Natural (B (I)));
      end loop;
      return R;
   end Str;

   Input : aliased constant Byte_Array :=
     Bytes ("{ ""b"": 1.0, ""a"": [1, 2, 3], ""c"": 1500 }");
   Src   : aliased Representation.Inputs.Array_Source (Input'Access);
   Doc   : Representation.Documents.Document (256, 4096);
   DR    : Representation.JSON.Documents.Decode_Result;
   Buf   : aliased Representation.Buffers.Buffer (4096);
   Snk   : Representation.Buffers.Buffer_Sink (Buf'Access);
   ER    : Representation.JSON.Documents.Encode_Result;
begin
   Put_Line ("input:     " & Str (Input));

   Representation.JSON.Documents.Decode (Doc, Src'Access, DR);
   if not DR.Ok then
      Put_Line ("decode failed: "
                & Representation.JSON.Documents.Error_Id (DR));
      return;
   end if;

   Representation.JSON.Documents.Encode
     (Doc, Representation.Documents.Root (Doc), Snk,
      Representation.JSON.Documents.Canonical, ER);
   Put_Line ("canonical: " & Str (Representation.Buffers.To_Byte_Array (Buf)));
end Codec_Roundtrip;
