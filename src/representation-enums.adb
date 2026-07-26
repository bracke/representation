package body Representation.Enums is

   package DM renames Representation.Documents;
   use type DM.Node_Kind;

   function Encode (Value : Enum_Type) return String is (Symbol (Value));

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   procedure Decode
     (Text : Byte_Array; Value : out Enum_Type; Found : out Boolean)
   is
      Candidate : constant String := To_String (Text);
   begin
      for E in Enum_Type'Range loop
         if Symbol (E) = Candidate then
            Value := E;
            Found := True;
            return;
         end if;
      end loop;
      Value := Enum_Type'First;
      Found := False;
   end Decode;

   procedure Decode_Node
     (Doc   : Representation.Documents.Document;
      N     : Representation.Documents.Node_Ref;
      Value : out Enum_Type;
      Found : out Boolean) is
   begin
      if DM.Kind (Doc, N) /= DM.String_Node then
         Value := Enum_Type'First;
         Found := False;
         return;
      end if;
      Decode (DM.Text (Doc, N), Value, Found);
   end Decode_Node;

end Representation.Enums;
