--  Representation.Buffers — a bounded, caller-owned output buffer and a Sink
--  adapter over it (§9.2, §32). Capacity is fixed at creation; appends past
--  capacity write nothing and report overflow (a controllable capacity
--  failure, never an unbounded grow — Rule 4.4).
with Representation.Outputs;
package Representation.Buffers
  with Preelaborate
is

   type Buffer (Capacity : Positive) is limited private;

   procedure Clear (B : in out Buffer);
   function Length (B : Buffer) return Byte_Count;
   function Is_Full (B : Buffer) return Boolean;

   --  Append Data. On overflow nothing is written and Overflowed is True.
   procedure Append
     (B          : in out Buffer;
      Data       : Byte_Array;
      Overflowed : out Boolean);

   procedure Append
     (B          : in out Buffer;
      Item       : Byte;
      Overflowed : out Boolean);

   function To_Byte_Array (B : Buffer) return Byte_Array;

   --  A Sink that appends into a caller-owned Buffer; the buffer must outlive
   --  the sink. Overflow surfaces as Write_Failed.
   type Buffer_Sink (Target : not null access Buffer) is
     limited new Representation.Outputs.Sink with null record;

   overriding procedure Write
     (To     : in out Buffer_Sink;
      Data   : Byte_Array;
      Status : out Representation.Outputs.Write_Status);

private

   type Buffer (Capacity : Positive) is limited record
      Length : Natural := 0;
      Data   : Byte_Array (1 .. Capacity);
   end record;

end Representation.Buffers;
