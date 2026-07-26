--  Representation.Envelopes — the standard response envelope (§38). An envelope
--  is a JSON object with canonical sections: the payload (data), and optional
--  meta, links, page, and errors sections, each already built as a Document
--  node (typically via Metadata/Links/Pagination.To_Object). Envelopes depends
--  only on the document model; it assembles and reads sections by their
--  canonical names and never invents section names on the wire.
with Representation.Documents;
package Representation.Envelopes is

   --  Assemble an envelope object. A section given as No_Node is omitted.
   function Build
     (Doc    : in out Representation.Documents.Document;
      Data   : Representation.Documents.Node_Ref;
      Meta   : Representation.Documents.Node_Ref :=
                 Representation.Documents.No_Node;
      Links  : Representation.Documents.Node_Ref :=
                 Representation.Documents.No_Node;
      Page   : Representation.Documents.Node_Ref :=
                 Representation.Documents.No_Node;
      Errors : Representation.Documents.Node_Ref :=
                 Representation.Documents.No_Node)
      return Representation.Documents.Node_Ref;

   --  Section accessors (No_Node when the section is absent or Env is not an
   --  object).
   function Data
     (Doc : Representation.Documents.Document;
      Env : Representation.Documents.Node_Ref)
      return Representation.Documents.Node_Ref;
   function Meta
     (Doc : Representation.Documents.Document;
      Env : Representation.Documents.Node_Ref)
      return Representation.Documents.Node_Ref;
   function Links
     (Doc : Representation.Documents.Document;
      Env : Representation.Documents.Node_Ref)
      return Representation.Documents.Node_Ref;
   function Page
     (Doc : Representation.Documents.Document;
      Env : Representation.Documents.Node_Ref)
      return Representation.Documents.Node_Ref;
   function Errors
     (Doc : Representation.Documents.Document;
      Env : Representation.Documents.Node_Ref)
      return Representation.Documents.Node_Ref;

   --  True when an errors section is present and non-empty.
   function Has_Errors
     (Doc : Representation.Documents.Document;
      Env : Representation.Documents.Node_Ref) return Boolean;

end Representation.Envelopes;
