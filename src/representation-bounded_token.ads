--  Representation.Bounded_Token — a private, fixed-capacity token holder.
--  Instantiated once per conceptually distinct identifier kind so that each
--  kind is a distinct, type-incompatible type sharing the same bounded,
--  validated representation (Rule 4.7). Construction is guarded by the
--  caller-supplied validity rule.
generic
   Max_Length : Natural;
   with function Is_Valid (S : String) return Boolean;
package Representation.Bounded_Token
  with Preelaborate
is

   type Token is private;

   function To_Token (S : String) return Token
     with Pre => Is_Valid (S);
   function Image (T : Token) return String;
   function Is_Empty (T : Token) return Boolean;

   Empty : constant Token;

private

   subtype Length_Range is Natural range 0 .. Max_Length;

   type Token is record
      Length : Length_Range := 0;
      Data   : String (1 .. Max_Length) := [others => ' '];
   end record;

   Empty : constant Token := (Length => 0, Data => [others => ' ']);

end Representation.Bounded_Token;
