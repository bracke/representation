package body Representation.Bounded_Token is

   function To_Token (S : String) return Token is
      Result : Token;
   begin
      Result.Length := S'Length;
      Result.Data (1 .. S'Length) := S;
      return Result;
   end To_Token;

   function Image (T : Token) return String is (T.Data (1 .. T.Length));

   function Is_Empty (T : Token) return Boolean is (T.Length = 0);

end Representation.Bounded_Token;
