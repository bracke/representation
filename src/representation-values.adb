with Representation.Numbers;

package body Representation.Values is

   package DM renames Representation.Documents;
   use type DM.Node_Kind;

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function Is_Null (Doc : Document; N : Node_Ref) return Boolean is
     (DM.Kind (Doc, N) = DM.Null_Node);

   procedure Get_Boolean
     (Doc : Document; N : Node_Ref;
      Value : out Boolean; Status : out Value_Status) is
   begin
      if DM.Kind (Doc, N) /= DM.Bool_Node then
         Value := False;
         Status := Value_Wrong_Kind;
         return;
      end if;
      Value := DM.Bool_Value (Doc, N);
      Status := Value_Ok;
   end Get_Boolean;

   procedure Get_Integer
     (Doc : Document; N : Node_Ref;
      Value : out Long_Long_Integer; Status : out Value_Status)
   is
      Outcome : Representation.Numbers.Parse_Outcome;
      use type Representation.Numbers.Parse_Outcome;
   begin
      Value := 0;
      if DM.Kind (Doc, N) /= DM.Number_Node then
         Status := Value_Wrong_Kind;
         return;
      end if;
      Representation.Numbers.Parse_Signed
        (To_String (DM.Text (Doc, N)), Value, Outcome);
      Status :=
        (case Outcome is
            when Representation.Numbers.Number_Ok       => Value_Ok,
            when Representation.Numbers.Number_Syntax    => Value_Malformed,
            when Representation.Numbers.Number_Overflow  => Value_Out_Of_Range);
   end Get_Integer;

   procedure Get_Unsigned
     (Doc : Document; N : Node_Ref;
      Value : out Interfaces.Unsigned_64; Status : out Value_Status)
   is
      Outcome : Representation.Numbers.Parse_Outcome;
      use type Representation.Numbers.Parse_Outcome;
   begin
      Value := 0;
      if DM.Kind (Doc, N) /= DM.Number_Node then
         Status := Value_Wrong_Kind;
         return;
      end if;
      Representation.Numbers.Parse_Unsigned
        (To_String (DM.Text (Doc, N)), Value, Outcome);
      Status :=
        (case Outcome is
            when Representation.Numbers.Number_Ok       => Value_Ok,
            when Representation.Numbers.Number_Syntax    => Value_Malformed,
            when Representation.Numbers.Number_Overflow  => Value_Out_Of_Range);
   end Get_Unsigned;

   procedure Get_Decimal
     (Doc : Document; N : Node_Ref;
      Value : out Representation.Decimals.Decimal; Status : out Value_Status)
   is
      Outcome : Representation.Decimals.Parse_Outcome;
      use type Representation.Decimals.Parse_Outcome;
   begin
      Value := Representation.Decimals.Zero;
      if DM.Kind (Doc, N) /= DM.Number_Node then
         Status := Value_Wrong_Kind;
         return;
      end if;
      Representation.Decimals.Parse
        (To_String (DM.Text (Doc, N)), Value, Outcome);
      Status :=
        (case Outcome is
            when Representation.Decimals.Decimal_Ok             => Value_Ok,
            when Representation.Decimals.Decimal_Syntax         => Value_Malformed,
            when Representation.Decimals.Decimal_Too_Many_Digits
               | Representation.Decimals.Decimal_Exponent_Range =>
                 Value_Out_Of_Range);
   end Get_Decimal;

   procedure Get_String
     (Doc : Document; N : Node_Ref;
      Buffer : out Byte_Array; Last : out Natural; Status : out Value_Status)
   is
   begin
      Last := Buffer'First - 1;
      if DM.Kind (Doc, N) /= DM.String_Node then
         Status := Value_Wrong_Kind;
         return;
      end if;
      declare
         Content : constant Byte_Array := DM.Text (Doc, N);
      begin
         if Content'Length > Buffer'Length then
            Status := Value_Overflow;
            return;
         end if;
         Buffer (Buffer'First .. Buffer'First + Content'Length - 1) := Content;
         Last := Buffer'First + Content'Length - 1;
         Status := Value_Ok;
      end;
   end Get_String;

   function Number_Text (Doc : Document; N : Node_Ref) return Byte_Array is
     (if DM.Kind (Doc, N) = DM.Number_Node then DM.Text (Doc, N)
      else [1 .. 0 => 0]);

   function Put_Null (Doc : in out Document) return Node_Ref is
     (DM.Add_Null (Doc));

   function Put_Boolean
     (Doc : in out Document; Value : Boolean) return Node_Ref is
     (DM.Add_Bool (Doc, Value));

   function Put_Integer
     (Doc : in out Document; Value : Long_Long_Integer) return Node_Ref is
     (DM.Add_Number (Doc, To_Bytes (Representation.Numbers.Image (Value))));

   function Put_Unsigned
     (Doc : in out Document; Value : Interfaces.Unsigned_64) return Node_Ref is
     (DM.Add_Number (Doc, To_Bytes (Representation.Numbers.Image (Value))));

   function Put_Decimal
     (Doc : in out Document; Value : Representation.Decimals.Decimal)
      return Node_Ref is
     (DM.Add_Number (Doc, To_Bytes (Representation.Decimals.Image (Value))));

   function Put_String
     (Doc : in out Document; Value : Byte_Array) return Node_Ref is
     (DM.Add_String (Doc, Value));

end Representation.Values;
