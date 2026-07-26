with Representation.Values;

package body Representation.Pagination is

   package DM renames Representation.Documents;
   package V renames Representation.Values;
   use type DM.Node_Ref;
   use type V.Value_Status;

   function To_Key (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Key;

   function Make
     (Limit    : Natural := 0;
      Offset   : Natural := 0;
      Total    : Natural := 0;
      Has_More : Boolean := False) return Page is
   begin
      return (Limit => Limit, Offset => Offset, Total => Total,
              Has_More => Has_More, Cursor_Len => 0, Cursor => [others => 0]);
   end Make;

   function Limit (P : Page) return Natural is (P.Limit);
   function Offset (P : Page) return Natural is (P.Offset);
   function Total (P : Page) return Natural is (P.Total);
   function Has_More (P : Page) return Boolean is (P.Has_More);
   function Cursor (P : Page) return Byte_Array is (P.Cursor (1 .. P.Cursor_Len));

   procedure Set_Cursor (P : in out Page; Value : Byte_Array; Ok : out Boolean) is
   begin
      if Value'Length > Max_Cursor then
         Ok := False;
         return;
      end if;
      P.Cursor_Len := Value'Length;
      if Value'Length > 0 then
         P.Cursor (1 .. Value'Length) := Value;
      end if;
      Ok := True;
   end Set_Cursor;

   function Nat_Node
     (Doc : in out DM.Document; N : Natural) return DM.Node_Ref is
     (V.Put_Integer (Doc, Long_Long_Integer (N)));

   function To_Object
     (P : Page; Doc : in out DM.Document) return DM.Node_Ref
   is
      Obj : constant DM.Node_Ref := DM.Add_Object (Doc);
   begin
      DM.Insert (Doc, Obj, To_Key ("limit"), Nat_Node (Doc, P.Limit));
      DM.Insert (Doc, Obj, To_Key ("offset"), Nat_Node (Doc, P.Offset));
      DM.Insert (Doc, Obj, To_Key ("total"), Nat_Node (Doc, P.Total));
      DM.Insert (Doc, Obj, To_Key ("has_more"),
                 V.Put_Boolean (Doc, P.Has_More));
      if P.Cursor_Len > 0 then
         DM.Insert (Doc, Obj, To_Key ("cursor"),
                    V.Put_String (Doc, P.Cursor (1 .. P.Cursor_Len)));
      end if;
      return Obj;
   end To_Object;

   procedure Read_Nat
     (Doc : DM.Document; N : DM.Node_Ref; Into : out Natural; Ok : in out Boolean)
   is
      LL : Long_Long_Integer;
      St : V.Value_Status;
   begin
      Into := 0;
      if N = DM.No_Node then
         return;   --  absent: keep default
      end if;
      V.Get_Integer (Doc, N, LL, St);
      if St = V.Value_Ok and then LL >= 0 then
         Into := Natural (LL);
      else
         Ok := False;
      end if;
   end Read_Nat;

   procedure From_Object
     (Doc : DM.Document;
      Obj : DM.Node_Ref;
      P   : out Page;
      Ok  : out Boolean)
   is
   begin
      P := Empty_Page;
      Ok := True;
      Read_Nat (Doc, DM.Find (Doc, Obj, To_Key ("limit")), P.Limit, Ok);
      Read_Nat (Doc, DM.Find (Doc, Obj, To_Key ("offset")), P.Offset, Ok);
      Read_Nat (Doc, DM.Find (Doc, Obj, To_Key ("total")), P.Total, Ok);

      declare
         HM : constant DM.Node_Ref := DM.Find (Doc, Obj, To_Key ("has_more"));
         B  : Boolean;
         St : V.Value_Status;
      begin
         if HM /= DM.No_Node then
            V.Get_Boolean (Doc, HM, B, St);
            if St = V.Value_Ok then
               P.Has_More := B;
            else
               Ok := False;
            end if;
         end if;
      end;

      declare
         CN   : constant DM.Node_Ref := DM.Find (Doc, Obj, To_Key ("cursor"));
         Buf  : Byte_Array (1 .. Max_Cursor);
         Last : Natural;
         St   : V.Value_Status;
      begin
         if CN /= DM.No_Node then
            V.Get_String (Doc, CN, Buf, Last, St);
            if St = V.Value_Ok then
               P.Cursor_Len := Last;
               if Last > 0 then
                  P.Cursor (1 .. Last) := Buf (1 .. Last);
               end if;
            else
               Ok := False;
            end if;
         end if;
      end;
   end From_Object;

end Representation.Pagination;
