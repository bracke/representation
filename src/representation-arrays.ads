--  Representation.Arrays — typed access to JSON array nodes (§29). Thin,
--  bounded helpers over the Document model plus a generic reader that decodes a
--  homogeneous array into a caller-provided fixed vector, reporting overflow
--  rather than growing. Element order is preserved (arrays are ordered).
with Representation.Documents;
package Representation.Arrays is

   function Is_Array
     (Doc : Representation.Documents.Document;
      N   : Representation.Documents.Node_Ref) return Boolean;

   --  Element count (0 for a non-array).
   function Length
     (Doc : Representation.Documents.Document;
      N   : Representation.Documents.Node_Ref) return Natural;

   --  1-based element (No_Node out of range or non-array).
   function Element
     (Doc   : Representation.Documents.Document;
      N     : Representation.Documents.Node_Ref;
      Index : Positive) return Representation.Documents.Node_Ref;

   function New_Array
     (Doc : in out Representation.Documents.Document)
      return Representation.Documents.Node_Ref;

   procedure Append
     (Doc  : in out Representation.Documents.Document;
      Arr  : Representation.Documents.Node_Ref;
      Elem : Representation.Documents.Node_Ref);

   --  Decode a homogeneous array into Into using Read_Element per element.
   --  Count is the number decoded. Status distinguishes success, a wrong node
   --  kind, a per-element failure, and vector overflow.
   generic
      type Element is private;
      type Vector is array (Positive range <>) of Element;
      with procedure Read_Element
        (Doc   : Representation.Documents.Document;
         N     : Representation.Documents.Node_Ref;
         Value : out Element;
         Ok    : out Boolean);
   package Reader is

      type Read_Status is (Read_Ok, Read_Wrong_Kind, Read_Element_Failed,
                           Read_Overflow);

      procedure Read
        (Doc    : Representation.Documents.Document;
         N      : Representation.Documents.Node_Ref;
         Into   : out Vector;
         Count  : out Natural;
         Status : out Read_Status);

   end Reader;

end Representation.Arrays;
