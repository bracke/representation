--  Representation.Links — a bounded, ordered set of hypermedia links (§38): a
--  relation name mapped to a target (href) string. Both are owned bytes in a
--  shared pool; the set is fixed-capacity and refuses growth past it. Renders to
--  and reads from a JSON object of { rel : href } string members.
with Representation.Documents;
package Representation.Links is

   type Link_Set (Capacity : Natural; Pool : Natural) is limited private;

   procedure Clear (LS : in out Link_Set);
   function Count (LS : Link_Set) return Natural;
   function Is_Full (LS : Link_Set) return Boolean;

   --  Add Rel => Href. Added is False if full, the pool cannot hold both, or
   --  Rel is already present (relations are unique).
   procedure Add
     (LS    : in out Link_Set;
      Rel   : Byte_Array;
      Href  : Byte_Array;
      Added : out Boolean);

   function Has (LS : Link_Set; Rel : Byte_Array) return Boolean;
   --  Href for Rel ("" if absent).
   function Href (LS : Link_Set; Rel : Byte_Array) return Byte_Array;

   function Relation (LS : Link_Set; Index : Positive) return Byte_Array
     with Pre => Index <= Count (LS);
   function Target (LS : Link_Set; Index : Positive) return Byte_Array
     with Pre => Index <= Count (LS);

   function To_Object
     (LS : Link_Set; Doc : in out Representation.Documents.Document)
      return Representation.Documents.Node_Ref;

   --  Read the string members of an object node as links (non-string members
   --  are skipped).
   procedure From_Object
     (LS  : in out Link_Set;
      Doc : Representation.Documents.Document;
      Obj : Representation.Documents.Node_Ref);

private

   type Link is record
      Rel_Start  : Positive := 1;
      Rel_Len    : Natural  := 0;
      Href_Start : Positive := 1;
      Href_Len   : Natural  := 0;
   end record;

   type Link_Array is array (Positive range <>) of Link;

   type Link_Set (Capacity : Natural; Pool : Natural) is limited record
      Items    : Link_Array (1 .. Capacity);
      Bytes    : Byte_Array (1 .. Pool);
      N        : Natural := 0;
      Pool_Top : Natural := 0;
   end record;

end Representation.Links;
