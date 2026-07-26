package body Representation.Fields is

   package Ids renames Representation.Identifiers;

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   function Make
     (Canonical   : Ids.Field_Id;
      Presence    : Presence_Policy := Required;
      Sensitivity : Representation.Errors.Sensitivity_Class :=
        Representation.Errors.Public) return Field_Descriptor is
   begin
      return (Canon       => Canonical,
              N_Alias     => 0,
              Aliases     => [others => <>],
              Policy      => Presence,
              Sensitivity => Sensitivity);
   end Make;

   function With_Alias
     (Field : Field_Descriptor;
      Alias : Ids.Field_Id) return Field_Descriptor
   is
      Result : Field_Descriptor := Field;
   begin
      if Result.N_Alias < Max_Aliases then
         Result.N_Alias := Result.N_Alias + 1;
         Result.Aliases (Result.N_Alias) := Alias;
      end if;
      return Result;
   end With_Alias;

   function Canonical (F : Field_Descriptor) return Ids.Field_Id is (F.Canon);

   function Presence (F : Field_Descriptor) return Presence_Policy is (F.Policy);

   function Sensitivity
     (F : Field_Descriptor) return Representation.Errors.Sensitivity_Class is
     (F.Sensitivity);

   function Alias_Count (F : Field_Descriptor) return Natural is (F.N_Alias);

   function Alias
     (F : Field_Descriptor; Index : Positive) return Ids.Field_Id is
     (F.Aliases (Index));

   function Matches (F : Field_Descriptor; Name : Byte_Array) return Boolean is
      S : constant String := To_String (Name);
   begin
      if Ids.Image (F.Canon) = S then
         return True;
      end if;
      for I in 1 .. F.N_Alias loop
         if Ids.Image (F.Aliases (I)) = S then
            return True;
         end if;
      end loop;
      return False;
   end Matches;

end Representation.Fields;
