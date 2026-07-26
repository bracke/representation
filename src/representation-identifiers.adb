package body Representation.Identifiers is

   function Is_Lower (C : Character) return Boolean is (C in 'a' .. 'z');
   function Is_Digit (C : Character) return Boolean is (C in '0' .. '9');
   function Is_Separator (C : Character) return Boolean is
     (C = '.' or else C = '-');

   function Valid_Identifier (S : String) return Boolean is
   begin
      if S'Length = 0 or else S'Length > Max_Identifier_Length then
         return False;
      end if;
      for I in S'Range loop
         declare
            C : constant Character := S (I);
         begin
            if Is_Separator (C) then
               --  No leading, trailing, or doubled separators.
               if I = S'First or else I = S'Last
                 or else Is_Separator (S (I - 1))
               then
                  return False;
               end if;
            elsif not (Is_Lower (C) or else Is_Digit (C)) then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Valid_Identifier;

end Representation.Identifiers;
