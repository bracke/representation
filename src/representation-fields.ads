--  Representation.Fields — the immutable descriptor of one object member (§27).
--  A field has a canonical external name (the only name ever emitted —
--  REP-INV-009), zero or more decode-only aliases (accepted on input for
--  backward compatibility, never written back), a presence policy, and a
--  sensitivity class that governs whether its value may appear in diagnostics
--  (REP-INV-017). Descriptors are plain values; a contract is an array of them.
with Representation.Identifiers;
with Representation.Errors;
package Representation.Fields is

   Max_Aliases : constant := 8;

   type Presence_Policy is
     (Required,               --  must be present (and non-null unless allowed)
      Optional,               --  may be absent
      Optional_With_Default); --  absent means the contract's default applies

   type Field_Descriptor is private;

   --  A contract is an array of field descriptors.
   type Field_Set is array (Positive range <>) of Field_Descriptor;

   --  Canonical is the name used for both encoding and (primary) decoding.
   function Make
     (Canonical   : Representation.Identifiers.Field_Id;
      Presence    : Presence_Policy := Required;
      Sensitivity : Representation.Errors.Sensitivity_Class :=
        Representation.Errors.Public) return Field_Descriptor;

   --  Return Field with Alias added as a decode-only alternative name. A no-op
   --  (returns Field unchanged) once Max_Aliases is reached.
   function With_Alias
     (Field : Field_Descriptor;
      Alias : Representation.Identifiers.Field_Id) return Field_Descriptor;

   function Canonical
     (F : Field_Descriptor) return Representation.Identifiers.Field_Id;
   function Presence (F : Field_Descriptor) return Presence_Policy;
   function Sensitivity
     (F : Field_Descriptor) return Representation.Errors.Sensitivity_Class;
   function Alias_Count (F : Field_Descriptor) return Natural;
   function Alias
     (F : Field_Descriptor; Index : Positive)
      return Representation.Identifiers.Field_Id
     with Pre => Index <= Alias_Count (F);

   --  Decode-side name matching: True if Name equals the canonical name or any
   --  alias. Name is the raw member name as it appears on the wire.
   function Matches (F : Field_Descriptor; Name : Byte_Array) return Boolean;

private

   type Alias_Array is
     array (1 .. Max_Aliases) of Representation.Identifiers.Field_Id;

   type Field_Descriptor is record
      Canon       : Representation.Identifiers.Field_Id;
      N_Alias     : Natural := 0;
      Aliases     : Alias_Array;
      Policy      : Presence_Policy := Required;
      Sensitivity : Representation.Errors.Sensitivity_Class :=
        Representation.Errors.Public;
   end record;

end Representation.Fields;
