package body Representation.Extensions is

   procedure Clear (Set : in out Extension_Set) is
   begin
      Set.N := 0;
      Set.Pool_Top := 0;
   end Clear;

   function Count (Set : Extension_Set) return Natural is (Set.N);

   function Is_Full (Set : Extension_Set) return Boolean is
     (Set.N >= Set.Capacity);

   procedure Add
     (Set   : in out Extension_Set;
      Core  : Representation.Fields.Field_Set;
      Name  : Byte_Array;
      Value : Representation.Documents.Node_Ref;
      Added : out Boolean) is
   begin
      Added := False;

      --  REP-INV-019: an extension may not carry a core field's name.
      for F in Core'Range loop
         if Representation.Fields.Matches (Core (F), Name) then
            return;
         end if;
      end loop;

      if Set.N >= Set.Capacity
        or else Set.Pool_Top + Name'Length > Set.Name_Pool
      then
         return;
      end if;

      Set.Entries (Set.N + 1) :=
        (Start => Set.Pool_Top + 1, Len => Name'Length, Val => Value);
      if Name'Length > 0 then
         Set.Pool (Set.Pool_Top + 1 .. Set.Pool_Top + Name'Length) := Name;
      end if;
      Set.Pool_Top := Set.Pool_Top + Name'Length;
      Set.N := Set.N + 1;
      Added := True;
   end Add;

   function Name (Set : Extension_Set; Index : Positive) return Byte_Array is
      E : Ext_Entry renames Set.Entries (Index);
   begin
      return Set.Pool (E.Start .. E.Start + E.Len - 1);
   end Name;

   function Value
     (Set : Extension_Set; Index : Positive)
      return Representation.Documents.Node_Ref is
     (Set.Entries (Index).Val);

   function Contains (Set : Extension_Set; Nm : Byte_Array) return Boolean is
   begin
      for I in 1 .. Set.N loop
         declare
            E : Ext_Entry renames Set.Entries (I);
         begin
            if E.Len = Nm'Length
              and then Set.Pool (E.Start .. E.Start + E.Len - 1) = Nm
            then
               return True;
            end if;
         end;
      end loop;
      return False;
   end Contains;

end Representation.Extensions;
