package body Representation.Outputs is

   overriding procedure Write
     (To     : in out Counting_Sink;
      Data   : Byte_Array;
      Status : out Write_Status) is
   begin
      To.Total := To.Total + Byte_Count (Data'Length);
      Status := Write_Ok;
   end Write;

   function Written (S : Counting_Sink) return Byte_Count is (S.Total);

   procedure Reset (S : in out Counting_Sink) is
   begin
      S.Total := 0;
   end Reset;

end Representation.Outputs;
