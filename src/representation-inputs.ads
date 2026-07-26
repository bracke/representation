--  Representation.Inputs — the pull-based byte source abstraction (§9.1).
--  Decoding never requires the whole payload in memory: it reads into a
--  caller-provided buffer, reports the count, distinguishes end-of-input, and
--  returns structured failure. One interface with small concrete adapters.
package Representation.Inputs
  with Preelaborate
is

   type Read_Status is (Read_Ok, Read_End, Read_Failed);

   type Source is limited interface;

   --  Read up to Into'Length bytes into Into. Last is the index of the final
   --  byte read (Into'First - 1 when none). Status = Read_End means the source
   --  is exhausted; Read_Failed means the underlying source errored.
   procedure Read
     (From   : in out Source;
      Into   : out Byte_Array;
      Last   : out Natural;
      Status : out Read_Status) is abstract;

   --  Source over a caller-owned byte array (a bounded memory region). The
   --  designated array must outlive the source.
   type Array_Source (Data : not null access constant Byte_Array) is
     limited new Source with private;

   overriding procedure Read
     (From   : in out Array_Source;
      Into   : out Byte_Array;
      Last   : out Natural;
      Status : out Read_Status);

private

   type Array_Source (Data : not null access constant Byte_Array) is
     limited new Source with record
      Consumed : Natural := 0;
   end record;

end Representation.Inputs;
