--  Representation.Outputs — the push-based byte sink abstraction (§9.2).
--  Encoding never requires the whole output to reside in memory: it writes to
--  a sink and propagates sink failure immediately (synchronous; no async
--  backpressure). A single interface with a small set of concrete adapters,
--  not a deep hierarchy (§33).
package Representation.Outputs
  with Preelaborate
is

   type Write_Status is (Write_Ok, Write_Failed);

   type Sink is limited interface;

   procedure Write
     (To     : in out Sink;
      Data   : Byte_Array;
      Status : out Write_Status) is abstract;

   --  Default no-op flush; buffered sinks override.
   procedure Flush (To : in out Sink; Status : out Write_Status) is null;

   --  A sink that discards bytes and counts them, for a size pre-pass ahead of
   --  bounded encoding.
   type Counting_Sink is limited new Sink with private;

   function Written (S : Counting_Sink) return Byte_Count;
   procedure Reset (S : in out Counting_Sink);

private

   type Counting_Sink is limited new Sink with record
      Total : Byte_Count := 0;
   end record;

   overriding procedure Write
     (To     : in out Counting_Sink;
      Data   : Byte_Array;
      Status : out Write_Status);

end Representation.Outputs;
