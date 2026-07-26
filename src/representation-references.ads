--  Representation.References — a typed, bounded reference value (§32). A
--  reference is a non-empty opaque target string, distinct from an ordinary
--  string so a contract can mark a member as "a reference to another resource"
--  without conflating it with free text. Construction and decoding validate
--  non-emptiness and the length bound and return a status (Rule 4.6); the
--  reference target is stored verbatim (no scheme interpretation in V1).
with Representation.Documents;
package Representation.References is

   Max_Reference_Length : constant := 1024;

   type Reference is private;
   Null_Reference : constant Reference;

   type Reference_Status is
     (Reference_Ok,
      Reference_Empty,       --  an empty target is not a valid reference
      Reference_Too_Long,    --  exceeds Max_Reference_Length
      Reference_Wrong_Kind); --  (decode) the node is not a string

   procedure Make
     (Target : Byte_Array; Ref : out Reference; Status : out Reference_Status);

   function Is_Null (Ref : Reference) return Boolean;

   --  The reference target bytes ("" for Null_Reference).
   function Target (Ref : Reference) return Byte_Array;

   --  Read a reference from a Document String node.
   procedure Decode
     (Doc    : Representation.Documents.Document;
      N      : Representation.Documents.Node_Ref;
      Ref    : out Reference;
      Status : out Reference_Status);

   --  Build a String node carrying the reference target (No_Node on overflow
   --  or when Ref is null).
   function Encode
     (Doc : in out Representation.Documents.Document; Ref : Reference)
      return Representation.Documents.Node_Ref;

private

   subtype Length_Range is Natural range 0 .. Max_Reference_Length;

   type Reference is record
      Len  : Length_Range := 0;
      Data : Byte_Array (1 .. Max_Reference_Length) := [others => 0];
   end record;

   Null_Reference : constant Reference := (Len => 0, Data => [others => 0]);

end Representation.References;
