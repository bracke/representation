--  Representation.JSON.Parser — a deterministic, defensive, pull-based JSON
--  event reader (§22.2). It drives Representation.JSON.Lexer and validates the
--  RFC 8259 grammar (a single top-level value; objects, arrays, nesting),
--  emitting a flat stream of structural/scalar events. Nothing is materialised
--  in memory beyond a bounded container stack and an optional bounded key store,
--  so arbitrarily large documents parse in constant space.
--
--  Everything is bounded and enforced before growth: nesting depth, object
--  members, array elements, total values, and a deterministic work budget
--  (Representation.Limits). Duplicate object keys are rejected (REP-INV-002)
--  when key tracking is enabled and sized. Malformed grammar, limit exhaustion,
--  and source failure surface as an Error event carrying a stable machine error
--  id — never an exception (Rule 4.6). End-of-document is End_Of_Input.
--
--  Value bytes for the most recent Key / String_Value / Number_Value event are
--  available through Value until the next call to Next.
with Representation.Inputs;
with Representation.Limits;
with Representation.JSON.Lexer;
package Representation.JSON.Parser is

   type Event_Kind is
     (Start_Object,
      End_Object,
      Start_Array,
      End_Array,
      Key,             --  an object member name; the value follows
      String_Value,
      Number_Value,
      Boolean_Value,   --  see Event.Bool
      Null_Value,
      End_Of_Input,
      Error);

   type Event is record
      Kind   : Event_Kind    := Error;
      Offset : Byte_Offset    := 0;   --  0-based byte offset of the token start
      Line   : Line_Number    := 1;   --  1-based
      Column : Column_Number  := 1;   --  1-based
      Depth  : Depth_Count    := 0;   --  open containers at this event
      Bool   : Boolean        := False;  --  valid when Kind = Boolean_Value
   end record;

   --  A parser reads from Source (which must outlive it) and owns fixed
   --  scratch: a Read_Capacity read buffer and Value_Capacity token scratch
   --  (both for the embedded lexer), a Depth_Capacity container stack, and an
   --  optional key store (Key_Pool_Bytes of key text across Key_Slots entries)
   --  used for duplicate-key detection. Set Key_Pool_Bytes or Key_Slots to 0 to
   --  parse structure only (duplicate detection off). The source is a
   --  discriminant so a stack-allocated source and its parser can be co-scoped.
   type Parser
     (Source         : not null access Representation.Inputs.Source'Class;
      Read_Capacity  : Positive;
      Value_Capacity : Positive;
      Depth_Capacity : Positive;
      Key_Pool_Bytes : Natural;
      Key_Slots      : Natural) is limited private;

   --  (Re)initialise the parser. Must be called once before the first Next.
   --  When Reject_Duplicate_Keys is True and the key store is sized, a repeated
   --  member name within one object is reported as a duplicate-field error.
   procedure Start
     (P      : in out Parser;
      Limits : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits;
      Reject_Duplicate_Keys : Boolean := True);

   --  Produce the next event. After End_Of_Input or Error, further calls keep
   --  returning that same terminal event.
   procedure Next (P : in out Parser; Ev : out Event);

   --  Raw bytes of the most recent Key / String_Value / Number_Value event
   --  (escapes intact for strings; validated number text for numbers).
   function Value (P : Parser) return Byte_Array;

   --  Stable machine error id for the most recent Error event.
   function Error_Id (P : Parser) return String;

private

   type Container_Kind is (In_Object, In_Array);

   type Frame is record
      Kind      : Container_Kind := In_Object;
      Count     : Natural        := 0;  --  members (object) / elements (array)
      Key_Base  : Natural        := 0;  --  key-table top at object entry
      Pool_Base : Natural        := 0;  --  key-pool top at object entry
   end record;

   type Frame_Stack is array (Positive range <>) of Frame;

   type Key_Ref is record
      Start : Positive := 1;
      Len   : Natural  := 0;
   end record;

   type Key_Table is array (Positive range <>) of Key_Ref;

   type Parse_State is
     (Expect_Doc_Value,     --  top level: the single document value
      Expect_Member_Value,  --  after ':' — a value (parent is an object)
      Expect_Element,       --  after ',' in an array — a value is required
      Expect_Array_Item,    --  after '[' — a value or ']'
      Expect_Object_Key,    --  after '{' — a key string or '}'
      Expect_Object_Key2,   --  after ',' in an object — a key string
      Expect_Colon,         --  after a key — consume ':'
      Expect_Comma_Or_End,  --  after an element/member value
      Doc_Complete,         --  the document value is complete; expect EOI
      Doc_Ended,            --  terminal: End_Of_Input has been emitted
      Parser_Failed);       --  terminal error state

   type Parser
     (Source         : not null access Representation.Inputs.Source'Class;
      Read_Capacity  : Positive;
      Value_Capacity : Positive;
      Depth_Capacity : Positive;
      Key_Pool_Bytes : Natural;
      Key_Slots      : Natural) is limited
   record
      Lex        : Representation.JSON.Lexer.Lexer
                     (Source, Read_Capacity, Value_Capacity);
      Limits     : Representation.Limits.Limits;
      Dedup      : Boolean := True;
      State      : Parse_State := Expect_Doc_Value;
      Top        : Natural := 0;              --  open containers
      Stack      : Frame_Stack (1 .. Depth_Capacity);
      Values     : Value_Count := 0;          --  total values emitted
      Work       : Value_Count := 0;          --  remaining work budget
      Key_Top    : Natural := 0;              --  keys currently tracked
      Pool_Top   : Natural := 0;              --  key-pool bytes in use
      Keys       : Key_Table (1 .. Key_Slots);
      Pool       : Byte_Array (1 .. Key_Pool_Bytes);
      Err        : String (1 .. 64) := [others => ' '];
      Err_Len    : Natural := 0;
      Term       : Event_Kind := End_Of_Input;  --  terminal event once reached
   end record;

end Representation.JSON.Parser;
