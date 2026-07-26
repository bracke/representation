with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Interfaces;               use Interfaces;
with Representation;           use Representation;
with Representation.Documents;
with Representation.Decimals;
with Representation.Values;
with Representation.Optionals;
with Representation.Enums;

package body Typed_Scalar_Tests is

   package DM renames Representation.Documents;
   package V renames Representation.Values;
   use type V.Value_Status;
   use type DM.Node_Kind;

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

   --  Optionals instance over Integer.
   package Opt_Int is new Representation.Optionals (Integer);

   --  Enums instance over a colour enumeration.
   type Colour is (Red, Green, Blue);
   function Colour_Symbol (C : Colour) return String is
     (case C is when Red => "red", when Green => "green", when Blue => "blue");
   package Colour_Enum is new Representation.Enums (Colour, Colour_Symbol);

   procedure Test_Values_Get (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (16, 128);
      NB   : constant DM.Node_Ref := DM.Add_Bool (Doc, True);
      NI   : constant DM.Node_Ref := DM.Add_Number (Doc, To_Bytes ("-42"));
      ND   : constant DM.Node_Ref := DM.Add_Number (Doc, To_Bytes ("1.5"));
      NS   : constant DM.Node_Ref := DM.Add_String (Doc, To_Bytes ("hi"));
      B    : Boolean;
      I    : Long_Long_Integer;
      U    : Unsigned_64;
      St   : V.Value_Status;
      Buf  : Byte_Array (1 .. 8);
      Last : Natural;
   begin
      V.Get_Boolean (Doc, NB, B, St);
      Assert (St = V.Value_Ok and then B, "boolean");
      V.Get_Integer (Doc, NI, I, St);
      Assert (St = V.Value_Ok and then I = -42, "integer");
      V.Get_Unsigned (Doc, NI, U, St);
      Assert (St = V.Value_Malformed, "negative is not unsigned");
      V.Get_String (Doc, NS, Buf, Last, St);
      Assert (St = V.Value_Ok and then To_Str (Buf (1 .. Last)) = "hi", "string");
      declare
         D  : Representation.Decimals.Decimal;
         Ds : V.Value_Status;
      begin
         V.Get_Decimal (Doc, ND, D, Ds);
         Assert (Ds = V.Value_Ok, "decimal parses 1.5");
      end;
   end Test_Values_Get;

   procedure Test_Values_Put (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : DM.Document (16, 128);
      N   : DM.Node_Ref;
   begin
      N := V.Put_Integer (Doc, 12345);
      Assert (To_Str (V.Number_Text (Doc, N)) = "12345", "put integer");
      N := V.Put_Unsigned (Doc, Unsigned_64'(18_000_000_000));
      Assert (To_Str (V.Number_Text (Doc, N)) = "18000000000", "put unsigned");
      N := V.Put_String (Doc, To_Bytes ("abc"));
      Assert (DM.Kind (Doc, N) = DM.String_Node, "put string");
      N := V.Put_Null (Doc);
      Assert (V.Is_Null (Doc, N), "put null");
   end Test_Values_Put;

   procedure Test_Values_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (16, 128);
      NS   : constant DM.Node_Ref := DM.Add_String (Doc, To_Bytes ("x"));
      NBig : constant DM.Node_Ref :=
        DM.Add_Number (Doc, To_Bytes ("999999999999999999999999"));
      NFrac : constant DM.Node_Ref := DM.Add_Number (Doc, To_Bytes ("1.5"));
      I    : Long_Long_Integer;
      St   : V.Value_Status;
      Buf  : Byte_Array (1 .. 1);
      Last : Natural;
      Bv   : Boolean;
   begin
      V.Get_Integer (Doc, NS, I, St);
      Assert (St = V.Value_Wrong_Kind, "string is not an integer");
      V.Get_Integer (Doc, NBig, I, St);
      Assert (St = V.Value_Out_Of_Range, "overflow reported, never wrapped");
      V.Get_Integer (Doc, NFrac, I, St);
      Assert (St = V.Value_Malformed, "1.5 is not an integer");
      V.Get_Boolean (Doc, NS, Bv, St);
      Assert (St = V.Value_Wrong_Kind, "string is not a boolean");
      V.Get_String (Doc, DM.Add_String (Doc, To_Bytes ("toolong")), Buf, Last, St);
      Assert (St = V.Value_Overflow, "buffer too small");
   end Test_Values_Errors;

   procedure Test_Optionals (T : in out Fixture) is
      pragma Unreferenced (T);
      A : constant Opt_Int.Optional := Opt_Int.Nothing;
      N : constant Opt_Int.Optional := Opt_Int.Null_Value;
      P : constant Opt_Int.Optional := Opt_Int.To_Optional (7);
      use type Opt_Int.Presence;
   begin
      Assert (Opt_Int.Is_Absent (A) and then not Opt_Int.Is_Null (A), "absent");
      Assert (Opt_Int.Is_Null (N) and then not Opt_Int.Is_Absent (N), "null");
      Assert (Opt_Int.Is_Value (P) and then Opt_Int.Value (P) = 7, "value");
      --  Absent and null are distinct states (REP-INV-007).
      Assert (Opt_Int.State (A) /= Opt_Int.State (N), "absent /= null");
      Assert (Opt_Int.Value_Or (A, 99) = 99, "absent falls back");
      Assert (Opt_Int.Value_Or (N, 99) = 99, "null falls back");
      Assert (Opt_Int.Value_Or (P, 99) = 7, "value wins");
   end Test_Optionals;

   procedure Test_Enums (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc   : DM.Document (8, 32);
      C     : Colour;
      Found : Boolean;
   begin
      Assert (Colour_Enum.Encode (Green) = "green", "encode symbol");
      Colour_Enum.Decode (To_Bytes ("blue"), C, Found);
      Assert (Found and then C = Blue, "decode known symbol");
      Colour_Enum.Decode (To_Bytes ("purple"), C, Found);
      Assert (not Found, "unknown symbol rejected, never guessed");
      Colour_Enum.Decode_Node
        (Doc, DM.Add_String (Doc, To_Bytes ("red")), C, Found);
      Assert (Found and then C = Red, "decode from string node");
      Colour_Enum.Decode_Node
        (Doc, DM.Add_Number (Doc, To_Bytes ("1")), C, Found);
      Assert (not Found, "non-string node is not an enum symbol");
   end Test_Enums;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Values: get", Test_Values_Get'Access));
      Suite.Add_Test
        (Caller.Create ("Values: put", Test_Values_Put'Access));
      Suite.Add_Test
        (Caller.Create ("Values: errors", Test_Values_Errors'Access));
      Suite.Add_Test
        (Caller.Create ("Optionals: tri-state", Test_Optionals'Access));
      Suite.Add_Test
        (Caller.Create ("Enums: explicit symbols", Test_Enums'Access));
   end Add_Tests;

end Typed_Scalar_Tests;
