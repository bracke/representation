--  Representation.Values — the typed scalar bridge between the Document model
--  and Ada scalar types (§24). Extraction reads a Document node as a Boolean,
--  exact integer, exact decimal, or UTF-8 string; construction builds the
--  corresponding scalar node. Numbers are parsed and imaged through the exact
--  paths (Representation.Numbers / .Decimals) and never routed through floating
--  point or silently rounded (REP-INV-003/018). Every extraction returns a
--  status value rather than raising (Rule 4.6).
with Interfaces;
with Representation.Documents;
with Representation.Decimals;
package Representation.Values is

   type Value_Status is
     (Value_Ok,
      Value_Wrong_Kind,     --  node is not the requested JSON kind
      Value_Out_Of_Range,   --  numeric magnitude exceeds the target type
      Value_Malformed,      --  number text is not a valid integer/decimal
      Value_Overflow);      --  the caller's output buffer is too small

   subtype Node_Ref is Representation.Documents.Node_Ref;
   subtype Document is Representation.Documents.Document;

   function Is_Null (Doc : Document; N : Node_Ref) return Boolean;

   ---------------------------------------------------------------------------
   --  Extraction. On any non-Ok status the out value is unspecified.
   ---------------------------------------------------------------------------

   procedure Get_Boolean
     (Doc : Document; N : Node_Ref;
      Value : out Boolean; Status : out Value_Status);

   procedure Get_Integer
     (Doc : Document; N : Node_Ref;
      Value : out Long_Long_Integer; Status : out Value_Status);

   procedure Get_Unsigned
     (Doc : Document; N : Node_Ref;
      Value : out Interfaces.Unsigned_64; Status : out Value_Status);

   procedure Get_Decimal
     (Doc : Document; N : Node_Ref;
      Value : out Representation.Decimals.Decimal; Status : out Value_Status);

   --  Copy a String node's UTF-8 content into Buffer. Last is the index of the
   --  final byte written (Buffer'First - 1 when empty); Value_Overflow if the
   --  content does not fit.
   procedure Get_String
     (Doc : Document; N : Node_Ref;
      Buffer : out Byte_Array; Last : out Natural; Status : out Value_Status);

   --  The verbatim number text of a Number node ("" for any other kind).
   function Number_Text (Doc : Document; N : Node_Ref) return Byte_Array;

   ---------------------------------------------------------------------------
   --  Construction. Each returns the new node (No_Node on arena overflow).
   ---------------------------------------------------------------------------

   function Put_Null (Doc : in out Document) return Node_Ref;
   function Put_Boolean (Doc : in out Document; Value : Boolean) return Node_Ref;
   function Put_Integer
     (Doc : in out Document; Value : Long_Long_Integer) return Node_Ref;
   function Put_Unsigned
     (Doc : in out Document; Value : Interfaces.Unsigned_64) return Node_Ref;
   function Put_Decimal
     (Doc : in out Document; Value : Representation.Decimals.Decimal)
      return Node_Ref;
   function Put_String
     (Doc : in out Document; Value : Byte_Array) return Node_Ref;

end Representation.Values;
