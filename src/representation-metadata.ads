--  Representation.Metadata — a bounded, ordered key -> value-node map (§38).
--  Metadata is a small set of named values attached to a representation (a
--  request id, a timestamp, a trace tag). Keys are owned string bytes; values
--  are handles into a caller-owned Document, so metadata composes directly with
--  the document model. Fixed capacity; a full map or exhausted key pool refuses
--  further entries rather than growing (Rule 4.4).
with Representation.Documents;
package Representation.Metadata is

   type Meta (Capacity : Natural; Key_Pool : Natural) is limited private;

   procedure Clear (M : in out Meta);
   function Count (M : Meta) return Natural;
   function Is_Full (M : Meta) return Boolean;

   --  Add Key => Value. Added is False if the map is full, the key pool cannot
   --  hold Key, or Key is already present (keys are unique).
   procedure Add
     (M     : in out Meta;
      Key   : Byte_Array;
      Value : Representation.Documents.Node_Ref;
      Added : out Boolean);

   function Has (M : Meta; Key : Byte_Array) return Boolean;
   --  Value for Key (No_Node if absent).
   function Get
     (M : Meta; Key : Byte_Array) return Representation.Documents.Node_Ref;

   function Key (M : Meta; Index : Positive) return Byte_Array
     with Pre => Index <= Count (M);
   function Value
     (M : Meta; Index : Positive) return Representation.Documents.Node_Ref
     with Pre => Index <= Count (M);

   --  Build an object node holding every entry (Key => Value) in insertion
   --  order (No_Node on arena overflow).
   function To_Object
     (M : Meta; Doc : in out Representation.Documents.Document)
      return Representation.Documents.Node_Ref;

   --  Record each member of an object node as a metadata entry (values are the
   --  member nodes themselves). Non-object nodes add nothing.
   procedure From_Object
     (M   : in out Meta;
      Doc : Representation.Documents.Document;
      Obj : Representation.Documents.Node_Ref);

private

   type Meta_Entry is record
      Start : Positive := 1;
      Len   : Natural  := 0;
      Node  : Representation.Documents.Node_Ref :=
                Representation.Documents.No_Node;
   end record;

   type Entry_Array is array (Positive range <>) of Meta_Entry;

   type Meta (Capacity : Natural; Key_Pool : Natural) is limited record
      Entries  : Entry_Array (1 .. Capacity);
      Pool     : Byte_Array (1 .. Key_Pool);
      N        : Natural := 0;
      Pool_Top : Natural := 0;
   end record;

end Representation.Metadata;
