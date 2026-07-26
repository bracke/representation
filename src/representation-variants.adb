with Representation.Objects;

package body Representation.Variants is

   package DM renames Representation.Documents;
   use type DM.Node_Kind;
   use type DM.Node_Ref;

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

   procedure Dispatch
     (Doc           : DM.Document;
      Obj           : DM.Node_Ref;
      Discriminator : Representation.Fields.Field_Descriptor;
      Tag           : out Variant_Tag;
      Status        : out Dispatch_Status)
   is
      Node : constant DM.Node_Ref :=
        Representation.Objects.Lookup (Doc, Obj, Discriminator);
   begin
      Tag := Variant_Tag'First;
      if Node = DM.No_Node then
         Status := Variant_Missing_Discriminator;
         return;
      end if;
      if DM.Kind (Doc, Node) /= DM.String_Node then
         Status := Variant_Wrong_Kind;
         return;
      end if;
      declare
         Value : constant String := To_String (DM.Text (Doc, Node));
      begin
         for T in Variant_Tag'Range loop
            if Symbol (T) = Value then
               Tag := T;
               Status := Variant_Ok;
               return;
            end if;
         end loop;
      end;
      Status := Variant_Unknown;
   end Dispatch;

   procedure Put_Discriminator
     (Doc           : in out DM.Document;
      Obj           : DM.Node_Ref;
      Discriminator : Representation.Fields.Field_Descriptor;
      Tag           : Variant_Tag) is
   begin
      Representation.Objects.Put_Field
        (Doc, Obj, Discriminator, DM.Add_String (Doc, To_Bytes (Symbol (Tag))));
   end Put_Discriminator;

end Representation.Variants;
