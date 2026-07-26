--  Representation.Documents — the bounded in-memory JSON value tree (§23). A
--  Document owns a fixed-capacity arena: a flat node table plus a text pool for
--  string content and number text. Nodes reference each other by handle
--  (Node_Ref), never by pointer, so a Document is a self-contained value with no
--  hidden global state and no unbounded growth. Every build step that would
--  exceed the arena fails softly: it returns No_Node and latches Overflowed, so
--  callers get a value, never an exception (Rule 4.6).
--
--  String and number text are stored verbatim as the caller supplies them:
--  strings as decoded UTF-8 content, numbers as validated JSON number text. The
--  JSON document codec (a child package) is responsible for decoding/encoding;
--  this package is codec-neutral structure only.
package Representation.Documents is

   type Node_Kind is
     (Null_Node,
      Bool_Node,
      Number_Node,
      String_Node,
      Array_Node,
      Object_Node);

   --  An opaque handle to a node within one Document. Handles are only valid
   --  for the Document that produced them and until the next Clear.
   type Node_Ref is private;
   No_Node : constant Node_Ref;

   --  A Document with room for Node_Capacity nodes and Text_Capacity bytes of
   --  string/number/key text.
   type Document (Node_Capacity : Positive; Text_Capacity : Positive)
     is limited private;

   --  Reset the arena to empty (no root, nothing allocated, not overflowed).
   procedure Clear (Doc : in out Document);

   --  True once any allocation has exceeded the arena. After overflow the tree
   --  is incomplete and readers/equality must not be trusted.
   function Overflowed (Doc : Document) return Boolean;

   ---------------------------------------------------------------------------
   --  Building. Each constructor returns the new node, or No_Node on overflow.
   ---------------------------------------------------------------------------

   function Add_Null (Doc : in out Document) return Node_Ref;
   function Add_Bool (Doc : in out Document; Value : Boolean) return Node_Ref;

   --  Number stored by its (already validated) JSON number text.
   function Add_Number (Doc : in out Document; Text : Byte_Array) return Node_Ref;

   --  String stored by its logical (decoded) UTF-8 content.
   function Add_String (Doc : in out Document; Text : Byte_Array) return Node_Ref;

   function Add_Array (Doc : in out Document) return Node_Ref;
   function Add_Object (Doc : in out Document) return Node_Ref;

   --  Append Child as the last element of Array Parent. No-op if either handle
   --  is No_Node or Parent is not an array.
   procedure Append
     (Doc : in out Document; Parent : Node_Ref; Child : Node_Ref);

   --  Add member (Key => Child) as the last member of Object Parent. Key is
   --  stored as decoded UTF-8. No-op on No_Node / non-object / text overflow
   --  (the latter latches Overflowed).
   procedure Insert
     (Doc   : in out Document;
      Parent : Node_Ref;
      Key    : Byte_Array;
      Child  : Node_Ref);

   procedure Set_Root (Doc : in out Document; Root : Node_Ref);
   function Root (Doc : Document) return Node_Ref;

   ---------------------------------------------------------------------------
   --  Reading.
   ---------------------------------------------------------------------------

   function Kind (Doc : Document; N : Node_Ref) return Node_Kind;
   function Bool_Value (Doc : Document; N : Node_Ref) return Boolean;

   --  Verbatim text of a String (decoded content) or Number (JSON text) node.
   function Text (Doc : Document; N : Node_Ref) return Byte_Array;

   --  Element/member count of an Array or Object (0 otherwise).
   function Length (Doc : Document; N : Node_Ref) return Natural;

   --  1-based element of an Array (No_Node if out of range / not an array).
   function Element
     (Doc : Document; N : Node_Ref; Index : Positive) return Node_Ref;

   --  1-based member of an Object: its key text and value handle.
   function Member_Key
     (Doc : Document; N : Node_Ref; Index : Positive) return Byte_Array;
   function Member
     (Doc : Document; N : Node_Ref; Index : Positive) return Node_Ref;

   --  First member of Object N whose key equals Key (No_Node if none).
   function Find
     (Doc : Document; N : Node_Ref; Key : Byte_Array) return Node_Ref;

   ---------------------------------------------------------------------------
   --  Structural equality: arrays compare element-wise in order; objects
   --  compare by matching member keys regardless of member order; numbers
   --  compare by exact decimal value (so 1 and 1.0 are equal), falling back to
   --  text when a value is outside the exact-decimal range.
   ---------------------------------------------------------------------------
   function Equal
     (A_Doc : Document; A : Node_Ref;
      B_Doc : Document; B : Node_Ref) return Boolean;

private

   type Node_Ref is new Natural;
   No_Node : constant Node_Ref := 0;

   type Node is record
      Kind         : Node_Kind := Null_Node;
      Bool         : Boolean   := False;
      Text_Start   : Positive  := 1;
      Text_Len     : Natural   := 0;
      Key_Start    : Positive  := 1;
      Key_Len      : Natural   := 0;
      First_Child  : Node_Ref  := No_Node;
      Last_Child   : Node_Ref  := No_Node;
      Next_Sibling : Node_Ref  := No_Node;
      Child_Count  : Natural   := 0;
   end record;

   type Node_Array is array (Positive range <>) of Node;

   type Document (Node_Capacity : Positive; Text_Capacity : Positive) is limited
   record
      Nodes    : Node_Array (1 .. Node_Capacity);
      Pool     : Byte_Array (1 .. Text_Capacity);
      Node_Top : Natural := 0;
      Pool_Top : Natural := 0;
      Root     : Node_Ref := No_Node;
      Overflow : Boolean := False;
   end record;

end Representation.Documents;
