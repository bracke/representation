package body Representation.Version is

   function Image (V : Version_Number) return String is
      Raw : constant String := Version_Number'Image (V);
   begin
      if Raw'Length > 0 and then Raw (Raw'First) = ' ' then
         return Raw (Raw'First + 1 .. Raw'Last);
      end if;
      return Raw;
   end Image;

   function Is_Active
     (V, Introduced : Version_Number;
      Removed       : Extended_Version := No_Version) return Boolean is
   begin
      if V < Introduced then
         return False;
      end if;
      if Removed /= No_Version and then Extended_Version (V) >= Removed then
         return False;
      end if;
      return True;
   end Is_Active;

end Representation.Version;
