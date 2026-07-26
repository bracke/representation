package body Representation.Metadata is

   package DM renames Representation.Documents;

   procedure Clear (M : in out Meta) is
   begin
      M.N := 0;
      M.Pool_Top := 0;
   end Clear;

   function Count (M : Meta) return Natural is (M.N);

   function Is_Full (M : Meta) return Boolean is (M.N >= M.Capacity);

   function Index_Of (M : Meta; K : Byte_Array) return Natural is
   begin
      for I in 1 .. M.N loop
         declare
            E : Meta_Entry renames M.Entries (I);
         begin
            if E.Len = K'Length
              and then M.Pool (E.Start .. E.Start + E.Len - 1) = K
            then
               return I;
            end if;
         end;
      end loop;
      return 0;
   end Index_Of;

   procedure Add
     (M     : in out Meta;
      Key   : Byte_Array;
      Value : DM.Node_Ref;
      Added : out Boolean) is
   begin
      Added := False;
      if M.N >= M.Capacity or else M.Pool_Top + Key'Length > M.Key_Pool
        or else Index_Of (M, Key) /= 0
      then
         return;
      end if;
      M.Entries (M.N + 1) :=
        (Start => M.Pool_Top + 1, Len => Key'Length, Node => Value);
      if Key'Length > 0 then
         M.Pool (M.Pool_Top + 1 .. M.Pool_Top + Key'Length) := Key;
      end if;
      M.Pool_Top := M.Pool_Top + Key'Length;
      M.N := M.N + 1;
      Added := True;
   end Add;

   function Has (M : Meta; Key : Byte_Array) return Boolean is
     (Index_Of (M, Key) /= 0);

   function Get (M : Meta; Key : Byte_Array) return DM.Node_Ref is
      I : constant Natural := Index_Of (M, Key);
   begin
      return (if I = 0 then DM.No_Node else M.Entries (I).Node);
   end Get;

   function Key (M : Meta; Index : Positive) return Byte_Array is
      E : Meta_Entry renames M.Entries (Index);
   begin
      return M.Pool (E.Start .. E.Start + E.Len - 1);
   end Key;

   function Value (M : Meta; Index : Positive) return DM.Node_Ref is
     (M.Entries (Index).Node);

   function To_Object
     (M : Meta; Doc : in out DM.Document) return DM.Node_Ref
   is
      Obj : constant DM.Node_Ref := DM.Add_Object (Doc);
   begin
      for I in 1 .. M.N loop
         DM.Insert (Doc, Obj, Key (M, I), M.Entries (I).Node);
      end loop;
      return Obj;
   end To_Object;

   procedure From_Object
     (M   : in out Meta;
      Doc : DM.Document;
      Obj : DM.Node_Ref)
   is
      Added : Boolean;
   begin
      for I in 1 .. DM.Length (Doc, Obj) loop
         Add (M, DM.Member_Key (Doc, Obj, I), DM.Member (Doc, Obj, I), Added);
         exit when not Added and then Is_Full (M);
      end loop;
   end From_Object;

end Representation.Metadata;
