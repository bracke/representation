package body Representation.Links is

   package DM renames Representation.Documents;
   use type DM.Node_Kind;

   procedure Clear (LS : in out Link_Set) is
   begin
      LS.N := 0;
      LS.Pool_Top := 0;
   end Clear;

   function Count (LS : Link_Set) return Natural is (LS.N);

   function Is_Full (LS : Link_Set) return Boolean is (LS.N >= LS.Capacity);

   function Index_Of (LS : Link_Set; Rel : Byte_Array) return Natural is
   begin
      for I in 1 .. LS.N loop
         declare
            L : Link renames LS.Items (I);
         begin
            if L.Rel_Len = Rel'Length
              and then LS.Bytes (L.Rel_Start .. L.Rel_Start + L.Rel_Len - 1)
                       = Rel
            then
               return I;
            end if;
         end;
      end loop;
      return 0;
   end Index_Of;

   procedure Add
     (LS    : in out Link_Set;
      Rel   : Byte_Array;
      Href  : Byte_Array;
      Added : out Boolean) is
   begin
      Added := False;
      if LS.N >= LS.Capacity
        or else LS.Pool_Top + Rel'Length + Href'Length > LS.Pool
        or else Index_Of (LS, Rel) /= 0
      then
         return;
      end if;
      declare
         RS : constant Positive := LS.Pool_Top + 1;
         HS : constant Positive := LS.Pool_Top + Rel'Length + 1;
      begin
         if Rel'Length > 0 then
            LS.Bytes (RS .. RS + Rel'Length - 1) := Rel;
         end if;
         if Href'Length > 0 then
            LS.Bytes (HS .. HS + Href'Length - 1) := Href;
         end if;
         LS.Items (LS.N + 1) :=
           (Rel_Start => RS, Rel_Len => Rel'Length,
            Href_Start => HS, Href_Len => Href'Length);
      end;
      LS.Pool_Top := LS.Pool_Top + Rel'Length + Href'Length;
      LS.N := LS.N + 1;
      Added := True;
   end Add;

   function Has (LS : Link_Set; Rel : Byte_Array) return Boolean is
     (Index_Of (LS, Rel) /= 0);

   function Relation (LS : Link_Set; Index : Positive) return Byte_Array is
      L : Link renames LS.Items (Index);
   begin
      return LS.Bytes (L.Rel_Start .. L.Rel_Start + L.Rel_Len - 1);
   end Relation;

   function Target (LS : Link_Set; Index : Positive) return Byte_Array is
      L : Link renames LS.Items (Index);
   begin
      return LS.Bytes (L.Href_Start .. L.Href_Start + L.Href_Len - 1);
   end Target;

   function Href (LS : Link_Set; Rel : Byte_Array) return Byte_Array is
      I : constant Natural := Index_Of (LS, Rel);
   begin
      if I = 0 then
         return [1 .. 0 => 0];
      end if;
      return Target (LS, I);
   end Href;

   function To_Object
     (LS : Link_Set; Doc : in out DM.Document) return DM.Node_Ref
   is
      Obj : constant DM.Node_Ref := DM.Add_Object (Doc);
   begin
      for I in 1 .. LS.N loop
         DM.Insert (Doc, Obj, Relation (LS, I),
                    DM.Add_String (Doc, Target (LS, I)));
      end loop;
      return Obj;
   end To_Object;

   procedure From_Object
     (LS  : in out Link_Set;
      Doc : DM.Document;
      Obj : DM.Node_Ref)
   is
      Added : Boolean;
   begin
      for I in 1 .. DM.Length (Doc, Obj) loop
         declare
            V : constant DM.Node_Ref := DM.Member (Doc, Obj, I);
         begin
            if DM.Kind (Doc, V) = DM.String_Node then
               Add (LS, DM.Member_Key (Doc, Obj, I), DM.Text (Doc, V), Added);
            end if;
         end;
      end loop;
   end From_Object;

end Representation.Links;
