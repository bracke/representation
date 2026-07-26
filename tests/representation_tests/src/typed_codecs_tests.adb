with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Inputs;
with Representation.Buffers;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Errors;
with Representation.Fields;
with Representation.Objects;
with Representation.Values;
with Representation.JSON.Documents;
with Representation.Typed_Codecs;

package body Typed_Codecs_Tests is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Val renames Representation.Values;
   package JD renames Representation.JSON.Documents;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function To_Str (B : Byte_Array) return String is
      R : String (1 .. B'Length);
   begin
      for I in B'Range loop
         R (I - B'First + 1) := Character'Val (Natural (B (I)));
      end loop;
      return R;
   end To_Str;

   --  The value type and its contract.
   type Person is record
      Id     : Long_Long_Integer := 0;
      Active : Boolean := False;
   end record;

   function F_Id return FLD.Field_Descriptor is
     (FLD.Make (Ids.To_Field_Id ("id"), FLD.Required));
   function F_Active return FLD.Field_Descriptor is
     (FLD.Make (Ids.To_Field_Id ("active"), FLD.Required));

   Contract : constant FLD.Field_Set := [F_Id, F_Active];

   procedure Read_Person
     (Doc : DM.Document; Obj_N : DM.Node_Ref; Value : out Person; Ok : out Boolean)
   is
      St1, St2 : Val.Value_Status;
      use type Val.Value_Status;
   begin
      Value := (others => <>);
      Val.Get_Integer (Doc, Obj.Lookup (Doc, Obj_N, F_Id), Value.Id, St1);
      Val.Get_Boolean (Doc, Obj.Lookup (Doc, Obj_N, F_Active), Value.Active, St2);
      Ok := St1 = Val.Value_Ok and then St2 = Val.Value_Ok;
   end Read_Person;

   procedure Write_Person
     (Doc : in out DM.Document; Value : Person; Obj_N : out DM.Node_Ref) is
   begin
      Obj_N := Obj.New_Object (Doc);
      Obj.Put_Field (Doc, Obj_N, F_Id, Val.Put_Integer (Doc, Value.Id));
      Obj.Put_Field (Doc, Obj_N, F_Active, Val.Put_Boolean (Doc, Value.Active));
   end Write_Person;

   package Codec is new Representation.Typed_Codecs
     (Value_Type => Person, Read => Read_Person, Write => Write_Person);

   function Decode_Str (JSON : String; P : out Person) return Codec.Decode_Report
   is
      Data : aliased constant Byte_Array := To_Bytes (JSON);
      Src  : aliased Representation.Inputs.Array_Source (Data'Access);
      Rep  : Codec.Decode_Report;
   begin
      Codec.Decode
        (Src'Access, Contract, P, Rep,
         Node_Capacity => 64, Text_Capacity => 512,
         Read_Capacity => 32, Value_Capacity => 128);
      return Rep;
   end Decode_Str;

   function Encode_Str (P : Person; Style : JD.Encoding) return String is
      Buf : aliased Representation.Buffers.Buffer (512);
      Snk : Representation.Buffers.Buffer_Sink (Buf'Access);
      Rep : Codec.Encode_Report;
   begin
      Codec.Encode (P, Snk, Rep, Style,
                    Node_Capacity => 64, Text_Capacity => 512);
      Assert (Rep.Ok, "encode ok");
      return To_Str (Representation.Buffers.To_Byte_Array (Buf));
   end Encode_Str;

   procedure Test_Decode_Order_Independent (T : in out Fixture) is
      pragma Unreferenced (T);
      P1, P2 : Person;
      R1 : constant Codec.Decode_Report :=
        Decode_Str ("{""id"":7,""active"":true}", P1);
      R2 : constant Codec.Decode_Report :=
        Decode_Str ("{""active"":true,""id"":7}", P2);
   begin
      Assert (R1.Ok and then P1 = (Id => 7, Active => True), "decode");
      Assert (R2.Ok and then P2 = P1, "member order does not matter");
   end Test_Decode_Order_Independent;

   procedure Test_Decode_Missing (T : in out Fixture) is
      pragma Unreferenced (T);
      P : Person;
      R : constant Codec.Decode_Report := Decode_Str ("{""id"":7}", P);
   begin
      Assert (not R.Ok
              and then Codec.Error_Id (R)
                       = Representation.Errors.Object_Missing_Field,
              "missing required field reported");
   end Test_Decode_Missing;

   procedure Test_Decode_Syntax (T : in out Fixture) is
      pragma Unreferenced (T);
      P : Person;
      R : constant Codec.Decode_Report := Decode_Str ("{""id"":", P);
      use type Representation.Errors.Error_Category;
   begin
      Assert (not R.Ok and then R.Category = Representation.Errors.Syntax_Error,
              "syntax error surfaced from the parser");
   end Test_Decode_Syntax;

   procedure Test_Encode (T : in out Fixture) is
      pragma Unreferenced (T);
      Out_JSON : constant String :=
        Encode_Str ((Id => 7, Active => True), JD.Compact);
   begin
      Assert (Out_JSON = "{""id"":7,""active"":true}",
              "compact encode: " & Out_JSON);
   end Test_Encode;

   procedure Test_Round_Trip (T : in out Fixture) is
      pragma Unreferenced (T);
      Original : constant Person := (Id => -123, Active => False);
      Encoded  : constant String := Encode_Str (Original, JD.Canonical);
      Decoded  : Person;
      R        : constant Codec.Decode_Report := Decode_Str (Encoded, Decoded);
   begin
      Assert (R.Ok and then Decoded = Original, "value survives round-trip");
   end Test_Round_Trip;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Typed_Codecs: order-independent decode",
         Test_Decode_Order_Independent'Access));
      Suite.Add_Test
        (Caller.Create ("Typed_Codecs: missing field",
         Test_Decode_Missing'Access));
      Suite.Add_Test
        (Caller.Create ("Typed_Codecs: syntax error", Test_Decode_Syntax'Access));
      Suite.Add_Test
        (Caller.Create ("Typed_Codecs: encode", Test_Encode'Access));
      Suite.Add_Test
        (Caller.Create ("Typed_Codecs: round trip", Test_Round_Trip'Access));
   end Add_Tests;

end Typed_Codecs_Tests;
