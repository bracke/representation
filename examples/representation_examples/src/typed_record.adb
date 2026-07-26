--  typed_record — bind an Ada record to a JSON contract with Representation.
--  Typed_Codecs. The caller supplies only Read/Write over the document model
--  (built from Objects/Values/Fields); the layer handles grammar, limits,
--  order-independence, duplicate/unknown members, and canonical output.
with Ada.Text_IO; use Ada.Text_IO;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Fields;
with Representation.Objects;
with Representation.Values;
with Representation.JSON.Documents;
with Representation.Typed_Codecs;

procedure Typed_Record is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Val renames Representation.Values;

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

   type Account is record
      Id     : Long_Long_Integer := 0;
      Active : Boolean := False;
   end record;

   function F_Id return FLD.Field_Descriptor is
     (FLD.Make (Ids.To_Field_Id ("id"), FLD.Required));
   function F_Active return FLD.Field_Descriptor is
     (FLD.Make (Ids.To_Field_Id ("active"), FLD.Required));

   Contract : constant FLD.Field_Set := [F_Id, F_Active];

   procedure Read_Account
     (Doc : DM.Document; Node : DM.Node_Ref;
      Value : out Account; Ok : out Boolean)
   is
      S1, S2 : Val.Value_Status;
      use type Val.Value_Status;
   begin
      Value := (others => <>);
      Val.Get_Integer (Doc, Obj.Lookup (Doc, Node, F_Id), Value.Id, S1);
      Val.Get_Boolean (Doc, Obj.Lookup (Doc, Node, F_Active), Value.Active, S2);
      Ok := S1 = Val.Value_Ok and then S2 = Val.Value_Ok;
   end Read_Account;

   procedure Write_Account
     (Doc : in out DM.Document; Value : Account; Node : out DM.Node_Ref) is
   begin
      Node := Obj.New_Object (Doc);
      Obj.Put_Field (Doc, Node, F_Id, Val.Put_Integer (Doc, Value.Id));
      Obj.Put_Field (Doc, Node, F_Active, Val.Put_Boolean (Doc, Value.Active));
   end Write_Account;

   package Codec is new Representation.Typed_Codecs
     (Value_Type => Account, Read => Read_Account, Write => Write_Account);

   --  Members in a different order than declared: decoding is order-independent.
   Input : aliased constant Byte_Array :=
     Bytes ("{ ""active"": true, ""id"": 42 }");
   Src   : aliased Representation.Inputs.Array_Source (Input'Access);
   A     : Account;
   Rep   : Codec.Decode_Report;

   Buf   : aliased Representation.Buffers.Buffer (256);
   Snk   : Representation.Buffers.Buffer_Sink (Buf'Access);
   ERep  : Codec.Encode_Report;
begin
   Codec.Decode (Src'Access, Contract, A, Rep);
   if not Rep.Ok then
      Put_Line ("decode failed: " & Codec.Error_Id (Rep));
      return;
   end if;
   Put_Line ("decoded:   id=" & Long_Long_Integer'Image (A.Id)
             & "  active=" & Boolean'Image (A.Active));

   Codec.Encode (A, Snk, ERep, Representation.JSON.Documents.Canonical);
   Put_Line ("encoded:   "
             & Str (Representation.Buffers.To_Byte_Array (Buf)));
end Typed_Record;
