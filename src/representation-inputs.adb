package body Representation.Inputs is

   overriding procedure Read
     (From   : in out Array_Source;
      Into   : out Byte_Array;
      Last   : out Natural;
      Status : out Read_Status)
   is
      Remaining : constant Natural := From.Data'Length - From.Consumed;
      N         : constant Natural := Natural'Min (Remaining, Into'Length);
      Src_First : constant Positive := From.Data'First + From.Consumed;
   begin
      if Remaining = 0 then
         Last := Into'First - 1;
         Status := Read_End;
         return;
      end if;
      Into (Into'First .. Into'First + N - 1) :=
        From.Data (Src_First .. Src_First + N - 1);
      From.Consumed := From.Consumed + N;
      Last := Into'First + N - 1;
      Status := Read_Ok;
   end Read;

end Representation.Inputs;
