--  Representation.Version — the transport-neutral contract/schema version
--  concept (§25). A version is a positive integral number; the core owns it
--  only as data. Transport adapters own how a version is selected (URI,
--  header, media type). There is never a global "active version".
package Representation.Version
  with Preelaborate
is

   type Version_Number is range 1 .. 2 ** 31 - 1;

   --  Extended range that also admits a distinguished "no version" value,
   --  used for open-ended removal bounds and absent embedded versions.
   subtype Extended_Version is
     Version_Number'Base range 0 .. Version_Number'Last;
   No_Version : constant Extended_Version := 0;

   --  Locale-neutral decimal image, no leading blank.
   function Image (V : Version_Number) return String;

   --  True when V is active in [Introduced .. Removed): a field/schema element
   --  is visible from its introduced version up to (but not including) its
   --  removed version. Removed = No_Version means "still present".
   function Is_Active
     (V, Introduced : Version_Number;
      Removed       : Extended_Version := No_Version) return Boolean;

end Representation.Version;
