--  Representation.Extensions — a bounded capture of unknown object members
--  (§30, REP-INV-011 Preserve / REP-INV-019). When a decode contract preserves
--  unknown members, they are held here as (name, value-handle) pairs so they can
--  be re-emitted unchanged. An extension may never carry the name of a declared
--  core field: Add refuses such a name, so an extension can never shadow or
--  override a core field. The set is fixed-capacity; a full set or exhausted
--  name pool refuses further additions rather than growing.
with Representation.Documents;
with Representation.Fields;
package Representation.Extensions is

   type Extension_Set (Capacity : Natural; Name_Pool : Natural) is limited private;

   procedure Clear (Set : in out Extension_Set);
   function Count (Set : Extension_Set) return Natural;
   function Is_Full (Set : Extension_Set) return Boolean;

   --  Record an unknown member (Name => Value). Added is False when Name
   --  matches any Core field (REP-INV-019), the set is full, or the name pool
   --  cannot hold Name.
   procedure Add
     (Set   : in out Extension_Set;
      Core  : Representation.Fields.Field_Set;
      Name  : Byte_Array;
      Value : Representation.Documents.Node_Ref;
      Added : out Boolean);

   function Name (Set : Extension_Set; Index : Positive) return Byte_Array
     with Pre => Index <= Count (Set);
   function Value
     (Set : Extension_Set; Index : Positive) return Representation.Documents.Node_Ref
     with Pre => Index <= Count (Set);
   function Contains (Set : Extension_Set; Nm : Byte_Array) return Boolean;

private

   type Ext_Entry is record
      Start : Positive := 1;
      Len   : Natural  := 0;
      Val   : Representation.Documents.Node_Ref :=
                Representation.Documents.No_Node;
   end record;

   type Ext_Array is array (Positive range <>) of Ext_Entry;

   type Extension_Set (Capacity : Natural; Name_Pool : Natural) is limited record
      Entries  : Ext_Array (1 .. Capacity);
      Pool     : Byte_Array (1 .. Name_Pool);
      N        : Natural := 0;
      Pool_Top : Natural := 0;
   end record;

end Representation.Extensions;
