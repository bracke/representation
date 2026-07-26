--  envelope — assemble a standard response envelope (data + meta + links + page)
--  from the common models and serialize it. Shows how Metadata/Links/Pagination
--  compose with Envelopes over one document arena.
with Ada.Text_IO; use Ada.Text_IO;

with Representation;             use Representation;
with Representation.Buffers;
with Representation.Documents;
with Representation.Metadata;
with Representation.Links;
with Representation.Pagination;
with Representation.Envelopes;
with Representation.JSON.Documents;

procedure Envelope is

   package DM renames Representation.Documents;
   package MD renames Representation.Metadata;
   package LK renames Representation.Links;
   package PG renames Representation.Pagination;
   package Env renames Representation.Envelopes;

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

   Doc   : DM.Document (256, 4096);
   M     : MD.Meta (4, 128);
   L     : LK.Link_Set (4, 256);
   Added : Boolean;

   Data  : DM.Node_Ref;
   Item  : DM.Node_Ref;
   Envl  : DM.Node_Ref;

   Buf   : aliased Representation.Buffers.Buffer (4096);
   Snk   : Representation.Buffers.Buffer_Sink (Buf'Access);
   ER    : Representation.JSON.Documents.Encode_Result;
begin
   --  Payload: a one-element array of items.
   Data := DM.Add_Array (Doc);
   Item := DM.Add_Object (Doc);
   DM.Insert (Doc, Item, Bytes ("id"), DM.Add_Number (Doc, Bytes ("7")));
   DM.Append (Doc, Data, Item);

   MD.Add (M, Bytes ("request-id"),
           DM.Add_String (Doc, Bytes ("req-42")), Added);
   LK.Add (L, Bytes ("self"), Bytes ("/items?page=1"), Added);
   LK.Add (L, Bytes ("next"), Bytes ("/items?page=2"), Added);

   Envl := Env.Build
     (Doc, Data,
      Meta  => MD.To_Object (M, Doc),
      Links => LK.To_Object (L, Doc),
      Page  => PG.To_Object
                 (PG.Make (Limit => 20, Offset => 0, Total => 137,
                           Has_More => True), Doc));

   Representation.JSON.Documents.Encode
     (Doc, Envl, Snk, Representation.JSON.Documents.Canonical, ER);
   Put_Line (Str (Representation.Buffers.To_Byte_Array (Buf)));
end Envelope;
