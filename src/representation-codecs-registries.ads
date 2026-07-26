--  Representation.Codecs.Registries — a bounded, caller-owned codec registry
--  (§39, REP-INV-020). It maps a stable codec id to its media-type string. The
--  registry is built incrementally, then Finalized; once final it is immutable —
--  Register is refused and only read-only lookup remains, so a finalized
--  registry can be shared without races or drift. There is no global registry
--  (REP-INV-010); a registry is a value the caller owns.
with Representation.Identifiers;
package Representation.Codecs.Registries is

   subtype Codec_Id is Representation.Identifiers.Codec_Id;

   type Registry (Capacity : Natural; Pool : Natural) is limited private;

   procedure Start (R : in out Registry);

   --  Register Id => Media_Type. Added is False if the registry is final, full,
   --  the pool cannot hold Media_Type, or Id is already registered.
   procedure Register
     (R          : in out Registry;
      Id         : Codec_Id;
      Media_Type : Byte_Array;
      Added      : out Boolean);

   procedure Finalize (R : in out Registry);
   function Is_Final (R : Registry) return Boolean;

   function Count (R : Registry) return Natural;
   function Contains (R : Registry; Id : Codec_Id) return Boolean;
   --  Media type for Id ("" if not registered).
   function Media_Type (R : Registry; Id : Codec_Id) return Byte_Array;

   function Identifier (R : Registry; Index : Positive) return Codec_Id
     with Pre => Index <= Count (R);

private

   type Codec_Entry is record
      Id         : Codec_Id;
      Media_Start : Positive := 1;
      Media_Len   : Natural  := 0;
   end record;

   type Entry_Array is array (Positive range <>) of Codec_Entry;

   type Registry (Capacity : Natural; Pool : Natural) is limited record
      Entries  : Entry_Array (1 .. Capacity);
      Bytes    : Byte_Array (1 .. Pool);
      N        : Natural := 0;
      Pool_Top : Natural := 0;
      Final    : Boolean := False;
   end record;

end Representation.Codecs.Registries;
