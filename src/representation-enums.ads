--  Representation.Enums — explicit enumeration codecs (§26). External enum
--  symbols are always declared by the caller through the Symbol function; they
--  are never derived from Enumeration'Image (a prohibited pattern — it couples
--  the wire contract to Ada identifiers and locale). Decoding matches an input
--  byte string against the declared symbols; an unmatched symbol is reported,
--  never guessed.
with Representation.Documents;
generic
   type Enum_Type is (<>);
   --  The canonical external symbol for each enumeration value.
   with function Symbol (Value : Enum_Type) return String;
package Representation.Enums is

   --  The canonical external symbol (= Symbol (Value)).
   function Encode (Value : Enum_Type) return String;

   --  Match Text against the declared symbols. Found is False (and Value is
   --  Enum_Type'First) when no symbol matches.
   procedure Decode
     (Text : Byte_Array; Value : out Enum_Type; Found : out Boolean);

   --  Decode from a Document String node. Found is False for a non-string node
   --  or an unmatched symbol.
   procedure Decode_Node
     (Doc   : Representation.Documents.Document;
      N     : Representation.Documents.Node_Ref;
      Value : out Enum_Type;
      Found : out Boolean);

end Representation.Enums;
