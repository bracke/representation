package body Representation.Paths is

   procedure Clear (P : out Path) is
   begin
      P.Count := 0;
      P.Dropped := False;
   end Clear;

   function Depth (P : Path) return Path_Depth is
     (Path_Depth (P.Count));

   function Truncated (P : Path) return Boolean is (P.Dropped);

   --  Store a name-bearing segment, truncating an over-long name and
   --  recording capacity overflow rather than growing.
   procedure Push_Name
     (P    : in out Path;
      Kind : Segment_Kind;
      Name : String)
   is
      Len : constant Name_Length_Range :=
        (if Name'Length > Max_Segment_Name
         then Max_Segment_Name else Name'Length);
   begin
      if P.Count = Max_Segments then
         P.Dropped := True;
         return;
      end if;
      P.Count := P.Count + 1;
      declare
         Seg : Segment (Kind);
      begin
         Seg.Name_Length := Len;
         Seg.Name (1 .. Len) := Name (Name'First .. Name'First + Len - 1);
         P.Items (P.Count) := Seg;
      end;
   end Push_Name;

   procedure Push_Field (P : in out Path; Name : String) is
   begin
      Push_Name (P, Field_Segment, Name);
   end Push_Field;

   procedure Push_Variant (P : in out Path; Name : String) is
   begin
      Push_Name (P, Variant_Segment, Name);
   end Push_Variant;

   procedure Push_Extension (P : in out Path; Name : String) is
   begin
      Push_Name (P, Extension_Segment, Name);
   end Push_Extension;

   procedure Push_Index (P : in out Path; Index : Array_Index) is
   begin
      if P.Count = Max_Segments then
         P.Dropped := True;
         return;
      end if;
      P.Count := P.Count + 1;
      P.Items (P.Count) := (Kind => Index_Segment, Index => Index);
   end Push_Index;

   procedure Pop (P : in out Path) is
   begin
      if P.Count > 0 then
         P.Count := P.Count - 1;
      end if;
   end Pop;

   function Is_Simple_Name (S : String) return Boolean is
   begin
      if S'Length = 0 then
         return False;
      end if;
      for I in S'Range loop
         declare
            C : constant Character := S (I);
            Head : constant Boolean := I = S'First;
         begin
            if C in 'a' .. 'z' | 'A' .. 'Z' | '_' then
               null;
            elsif not Head and then C in '0' .. '9' then
               null;
            else
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Simple_Name;

   function Index_Image (Index : Array_Index) return String is
      Raw : constant String := Array_Index'Image (Index);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);  --  drop the leading blank
   end Index_Image;

   function Render (P : Path) return String is
      --  Bounded worst case: "$" + every segment in escaped bracket form,
      --  plus a truncation marker.
      Capacity : constant Positive :=
        1 + Max_Segments * (2 * Max_Segment_Name + 8) + 8;
      Buffer   : String (1 .. Capacity);
      Last     : Natural := 0;

      procedure Put (S : String) is
      begin
         Buffer (Last + 1 .. Last + S'Length) := S;
         Last := Last + S'Length;
      end Put;

      procedure Put_Bracket_Quoted (Name : String) is
      begin
         Put ("[""");
         for C of Name loop
            if C = '\' or else C = '"' then
               Put ((1 => '\', 2 => C));
            else
               Put ((1 => C));
            end if;
         end loop;
         Put ("""]");
      end Put_Bracket_Quoted;
   begin
      Put ("$");
      for I in 1 .. P.Count loop
         declare
            Seg : Segment renames P.Items (I);
         begin
            case Seg.Kind is
               when Index_Segment =>
                  Put ("[" & Index_Image (Seg.Index) & "]");
               when Field_Segment | Variant_Segment | Extension_Segment =>
                  declare
                     Name : constant String := Seg.Name (1 .. Seg.Name_Length);
                  begin
                     if Is_Simple_Name (Name) then
                        Put ("." & Name);
                     else
                        Put_Bracket_Quoted (Name);
                     end if;
                  end;
            end case;
         end;
      end loop;
      if P.Dropped then
         Put (".<truncated>");
      end if;
      return Buffer (1 .. Last);
   end Render;

end Representation.Paths;
