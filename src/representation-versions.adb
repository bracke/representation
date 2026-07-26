package body Representation.Versions is

   use type Version_Number;

   procedure Start (VS : in out Version_Set; Current : Version_Number) is
   begin
      VS.Cur     := Current;
      VS.N       := 0;
      VS.Final   := False;
      VS.Started := True;
   end Start;

   procedure Add_Supported
     (VS : in out Version_Set; V : Version_Number; Added : out Boolean) is
   begin
      Added := False;
      if VS.Final or else not VS.Started or else VS.N >= VS.Capacity
        or else V >= VS.Cur
      then
         return;
      end if;
      --  Ignore a duplicate silently (idempotent), but report it as not added.
      for I in 1 .. VS.N loop
         if VS.Older (I) = V then
            return;
         end if;
      end loop;
      VS.N := VS.N + 1;
      VS.Older (VS.N) := V;
      Added := True;
   end Add_Supported;

   procedure Finalize (VS : in out Version_Set) is
   begin
      VS.Final := True;
   end Finalize;

   function Is_Final (VS : Version_Set) return Boolean is (VS.Final);

   function Current (VS : Version_Set) return Version_Number is (VS.Cur);

   function Is_Supported
     (VS : Version_Set; V : Version_Number) return Boolean is
   begin
      if V = VS.Cur then
         return True;
      end if;
      for I in 1 .. VS.N loop
         if VS.Older (I) = V then
            return True;
         end if;
      end loop;
      return False;
   end Is_Supported;

   function Resolve
     (VS : Version_Set; V : Version_Number) return Resolution is
   begin
      if V = VS.Cur then
         return Version_Current;
      elsif V > VS.Cur then
         return Version_Too_New;   --  never silently downgrade to Current
      elsif Is_Supported (VS, V) then
         return Version_Migratable;
      else
         return Version_Unsupported;
      end if;
   end Resolve;

end Representation.Versions;
