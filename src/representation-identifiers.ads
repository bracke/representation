--  Representation.Identifiers — stable, contract-level identifiers (§13,
--  Rule 4.7). A stable identifier is a non-empty bounded token of lowercase
--  ASCII letters, digits, and the separators '.' and '-'. Separators may not
--  lead, trail, repeat, or be adjacent. Identifiers are locale-neutral and
--  never appear on the wire unless a contract deliberately puts them there;
--  renaming an Ada component must not change any external contract.
--
--  The schema / field / codec / error identifier kinds are distinct,
--  type-incompatible types (each a separate instantiation of Bounded_Token),
--  so a schema id can never be passed where a field id is expected.
with Representation.Bounded_Token;
package Representation.Identifiers
  with Preelaborate
is

   Max_Identifier_Length : constant := 128;

   function Valid_Identifier (S : String) return Boolean;

   package Schema_Ids is new Representation.Bounded_Token
     (Max_Length => Max_Identifier_Length, Is_Valid => Valid_Identifier);
   package Field_Ids is new Representation.Bounded_Token
     (Max_Length => Max_Identifier_Length, Is_Valid => Valid_Identifier);
   package Codec_Ids is new Representation.Bounded_Token
     (Max_Length => Max_Identifier_Length, Is_Valid => Valid_Identifier);
   package Error_Ids is new Representation.Bounded_Token
     (Max_Length => Max_Identifier_Length, Is_Valid => Valid_Identifier);

   subtype Schema_Id is Schema_Ids.Token;
   subtype Field_Id  is Field_Ids.Token;
   subtype Codec_Id  is Codec_Ids.Token;
   subtype Error_Id  is Error_Ids.Token;

   function To_Schema_Id (S : String) return Schema_Id is (Schema_Ids.To_Token (S))
     with Pre => Valid_Identifier (S);
   function To_Field_Id (S : String) return Field_Id is (Field_Ids.To_Token (S))
     with Pre => Valid_Identifier (S);
   function To_Codec_Id (S : String) return Codec_Id is (Codec_Ids.To_Token (S))
     with Pre => Valid_Identifier (S);
   function To_Error_Id (S : String) return Error_Id is (Error_Ids.To_Token (S))
     with Pre => Valid_Identifier (S);

   function Image (Id : Schema_Id) return String is (Schema_Ids.Image (Id));
   function Image (Id : Field_Id) return String is (Field_Ids.Image (Id));
   function Image (Id : Codec_Id) return String is (Codec_Ids.Image (Id));
   function Image (Id : Error_Id) return String is (Error_Ids.Image (Id));

end Representation.Identifiers;
