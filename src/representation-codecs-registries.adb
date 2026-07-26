package body Representation.Codecs.Registries is

   use type Codec_Id;

   procedure Start (R : in out Registry) is
   begin
      R.N := 0;
      R.Pool_Top := 0;
      R.Final := False;
   end Start;

   function Index_Of (R : Registry; Id : Codec_Id) return Natural is
   begin
      for I in 1 .. R.N loop
         if R.Entries (I).Id = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Index_Of;

   procedure Register
     (R          : in out Registry;
      Id         : Codec_Id;
      Media_Type : Byte_Array;
      Added      : out Boolean) is
   begin
      Added := False;
      if R.Final or else R.N >= R.Capacity
        or else R.Pool_Top + Media_Type'Length > R.Pool
        or else Index_Of (R, Id) /= 0
      then
         return;
      end if;
      R.Entries (R.N + 1) :=
        (Id => Id, Media_Start => R.Pool_Top + 1, Media_Len => Media_Type'Length);
      if Media_Type'Length > 0 then
         R.Bytes (R.Pool_Top + 1 .. R.Pool_Top + Media_Type'Length) :=
           Media_Type;
      end if;
      R.Pool_Top := R.Pool_Top + Media_Type'Length;
      R.N := R.N + 1;
      Added := True;
   end Register;

   procedure Finalize (R : in out Registry) is
   begin
      R.Final := True;
   end Finalize;

   function Is_Final (R : Registry) return Boolean is (R.Final);

   function Count (R : Registry) return Natural is (R.N);

   function Contains (R : Registry; Id : Codec_Id) return Boolean is
     (Index_Of (R, Id) /= 0);

   function Media_Type (R : Registry; Id : Codec_Id) return Byte_Array is
      I : constant Natural := Index_Of (R, Id);
   begin
      if I = 0 then
         return [1 .. 0 => 0];
      end if;
      declare
         E : Codec_Entry renames R.Entries (I);
      begin
         return R.Bytes (E.Media_Start .. E.Media_Start + E.Media_Len - 1);
      end;
   end Media_Type;

   function Identifier (R : Registry; Index : Positive) return Codec_Id is
     (R.Entries (Index).Id);

end Representation.Codecs.Registries;
