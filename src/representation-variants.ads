--  Representation.Variants — discriminated-union dispatch (§31, REP-INV-012).
--  A variant object carries a discriminator member whose string value selects
--  one declared variant. Dispatch matches that value only against the declared
--  discriminator symbols (supplied by the caller through Symbol); an
--  unrecognised value is reported as Variant_Unknown and never mapped to a
--  default or nearest tag. As with enums, symbols are declared, never derived
--  from Enumeration'Image.
with Representation.Documents;
with Representation.Fields;
generic
   type Variant_Tag is (<>);
   --  The discriminator symbol that selects each variant.
   with function Symbol (Tag : Variant_Tag) return String;
package Representation.Variants is

   type Dispatch_Status is
     (Variant_Ok,
      Variant_Missing_Discriminator,  --  the discriminator member is absent
      Variant_Wrong_Kind,             --  the discriminator is not a string
      Variant_Unknown);               --  the value matches no declared variant

   --  Select the variant of Obj from its Discriminator member.
   procedure Dispatch
     (Doc           : Representation.Documents.Document;
      Obj           : Representation.Documents.Node_Ref;
      Discriminator : Representation.Fields.Field_Descriptor;
      Tag           : out Variant_Tag;
      Status        : out Dispatch_Status);

   --  Write the discriminator member (canonical name, Tag's symbol as value).
   procedure Put_Discriminator
     (Doc           : in out Representation.Documents.Document;
      Obj           : Representation.Documents.Node_Ref;
      Discriminator : Representation.Fields.Field_Descriptor;
      Tag           : Variant_Tag);

end Representation.Variants;
