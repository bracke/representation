package body Representation.Buffers is

   procedure Clear (B : in out Buffer) is
   begin
      B.Length := 0;
   end Clear;

   function Length (B : Buffer) return Byte_Count is (Byte_Count (B.Length));

   function Is_Full (B : Buffer) return Boolean is (B.Length = B.Capacity);

   procedure Append
     (B          : in out Buffer;
      Data       : Byte_Array;
      Overflowed : out Boolean) is
   begin
      if B.Length + Data'Length > B.Capacity then
         Overflowed := True;
         return;
      end if;
      B.Data (B.Length + 1 .. B.Length + Data'Length) := Data;
      B.Length := B.Length + Data'Length;
      Overflowed := False;
   end Append;

   procedure Append
     (B          : in out Buffer;
      Item       : Byte;
      Overflowed : out Boolean) is
   begin
      if B.Length >= B.Capacity then
         Overflowed := True;
         return;
      end if;
      B.Length := B.Length + 1;
      B.Data (B.Length) := Item;
      Overflowed := False;
   end Append;

   function To_Byte_Array (B : Buffer) return Byte_Array is
     (B.Data (1 .. B.Length));

   overriding procedure Write
     (To     : in out Buffer_Sink;
      Data   : Byte_Array;
      Status : out Representation.Outputs.Write_Status)
   is
      Overflowed : Boolean;
   begin
      Append (To.Target.all, Data, Overflowed);
      Status :=
        (if Overflowed
         then Representation.Outputs.Write_Failed
         else Representation.Outputs.Write_Ok);
   end Write;

end Representation.Buffers;
