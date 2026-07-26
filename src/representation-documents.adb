with Representation.Decimals;

package body Representation.Documents is

   procedure Clear (Doc : in out Document) is
   begin
      Doc.Node_Top := 0;
      Doc.Pool_Top := 0;
      Doc.Root     := No_Node;
      Doc.Overflow := False;
   end Clear;

   function Overflowed (Doc : Document) return Boolean is (Doc.Overflow);

   --  Allocate a fresh node of the given kind; No_Node (and latch Overflowed)
   --  when the node table is full.
   function New_Node (Doc : in out Document; K : Node_Kind) return Node_Ref is
   begin
      if Doc.Node_Top >= Doc.Node_Capacity then
         Doc.Overflow := True;
         return No_Node;
      end if;
      Doc.Node_Top := Doc.Node_Top + 1;
      Doc.Nodes (Doc.Node_Top) := (Kind => K, others => <>);
      return Node_Ref (Doc.Node_Top);
   end New_Node;

   --  Copy Text into the pool; report its placement. False (and latch
   --  Overflowed) when the pool cannot hold it.
   function Store
     (Doc : in out Document; Text : Byte_Array; Start : out Positive;
      Len : out Natural) return Boolean is
   begin
      Start := 1;
      Len := 0;
      if Doc.Pool_Top + Text'Length > Doc.Text_Capacity then
         Doc.Overflow := True;
         return False;
      end if;
      if Text'Length > 0 then
         Doc.Pool (Doc.Pool_Top + 1 .. Doc.Pool_Top + Text'Length) := Text;
         Start := Doc.Pool_Top + 1;
      end if;
      Len := Text'Length;
      Doc.Pool_Top := Doc.Pool_Top + Text'Length;
      return True;
   end Store;

   function Add_Null (Doc : in out Document) return Node_Ref is
     (New_Node (Doc, Null_Node));

   function Add_Bool (Doc : in out Document; Value : Boolean) return Node_Ref is
      N : constant Node_Ref := New_Node (Doc, Bool_Node);
   begin
      if N /= No_Node then
         Doc.Nodes (Positive (N)).Bool := Value;
      end if;
      return N;
   end Add_Bool;

   function Add_Text_Node
     (Doc : in out Document; K : Node_Kind; Text : Byte_Array) return Node_Ref
   is
      N     : constant Node_Ref := New_Node (Doc, K);
      Start : Positive;
      Len   : Natural;
   begin
      if N = No_Node then
         return No_Node;
      end if;
      if not Store (Doc, Text, Start, Len) then
         return No_Node;
      end if;
      Doc.Nodes (Positive (N)).Text_Start := Start;
      Doc.Nodes (Positive (N)).Text_Len   := Len;
      return N;
   end Add_Text_Node;

   function Add_Number
     (Doc : in out Document; Text : Byte_Array) return Node_Ref is
     (Add_Text_Node (Doc, Number_Node, Text));

   function Add_String
     (Doc : in out Document; Text : Byte_Array) return Node_Ref is
     (Add_Text_Node (Doc, String_Node, Text));

   function Add_Array (Doc : in out Document) return Node_Ref is
     (New_Node (Doc, Array_Node));

   function Add_Object (Doc : in out Document) return Node_Ref is
     (New_Node (Doc, Object_Node));

   --  Link Child as the last child of container Parent.
   procedure Link_Child
     (Doc : in out Document; Parent : Node_Ref; Child : Node_Ref)
   is
      P : Node renames Doc.Nodes (Positive (Parent));
   begin
      Doc.Nodes (Positive (Child)).Next_Sibling := No_Node;
      if P.First_Child = No_Node then
         P.First_Child := Child;
      else
         Doc.Nodes (Positive (P.Last_Child)).Next_Sibling := Child;
      end if;
      P.Last_Child  := Child;
      P.Child_Count := P.Child_Count + 1;
   end Link_Child;

   procedure Append
     (Doc : in out Document; Parent : Node_Ref; Child : Node_Ref) is
   begin
      if Parent = No_Node or else Child = No_Node
        or else Doc.Nodes (Positive (Parent)).Kind /= Array_Node
      then
         return;
      end if;
      Link_Child (Doc, Parent, Child);
   end Append;

   procedure Insert
     (Doc    : in out Document;
      Parent : Node_Ref;
      Key    : Byte_Array;
      Child  : Node_Ref)
   is
      Start : Positive;
      Len   : Natural;
   begin
      if Parent = No_Node or else Child = No_Node
        or else Doc.Nodes (Positive (Parent)).Kind /= Object_Node
      then
         return;
      end if;
      if not Store (Doc, Key, Start, Len) then
         return;
      end if;
      Doc.Nodes (Positive (Child)).Key_Start := Start;
      Doc.Nodes (Positive (Child)).Key_Len   := Len;
      Link_Child (Doc, Parent, Child);
   end Insert;

   procedure Set_Root (Doc : in out Document; Root : Node_Ref) is
   begin
      Doc.Root := Root;
   end Set_Root;

   function Root (Doc : Document) return Node_Ref is (Doc.Root);

   function Kind (Doc : Document; N : Node_Ref) return Node_Kind is
     (if N = No_Node then Null_Node else Doc.Nodes (Positive (N)).Kind);

   function Bool_Value (Doc : Document; N : Node_Ref) return Boolean is
     (N /= No_Node and then Doc.Nodes (Positive (N)).Bool);

   function Text (Doc : Document; N : Node_Ref) return Byte_Array is
   begin
      if N = No_Node then
         return [1 .. 0 => 0];
      end if;
      declare
         Nd : Node renames Doc.Nodes (Positive (N));
      begin
         return Doc.Pool (Nd.Text_Start .. Nd.Text_Start + Nd.Text_Len - 1);
      end;
   end Text;

   function Length (Doc : Document; N : Node_Ref) return Natural is
     (if N = No_Node then 0 else Doc.Nodes (Positive (N)).Child_Count);

   --  The Index-th child (1-based) of container N, or No_Node.
   function Nth_Child
     (Doc : Document; N : Node_Ref; Index : Positive) return Node_Ref
   is
      Cur : Node_Ref;
      I   : Natural := 0;
   begin
      if N = No_Node then
         return No_Node;
      end if;
      Cur := Doc.Nodes (Positive (N)).First_Child;
      while Cur /= No_Node loop
         I := I + 1;
         if I = Index then
            return Cur;
         end if;
         Cur := Doc.Nodes (Positive (Cur)).Next_Sibling;
      end loop;
      return No_Node;
   end Nth_Child;

   function Element
     (Doc : Document; N : Node_Ref; Index : Positive) return Node_Ref is
     (if N /= No_Node and then Doc.Nodes (Positive (N)).Kind = Array_Node
      then Nth_Child (Doc, N, Index) else No_Node);

   function Member
     (Doc : Document; N : Node_Ref; Index : Positive) return Node_Ref is
     (if N /= No_Node and then Doc.Nodes (Positive (N)).Kind = Object_Node
      then Nth_Child (Doc, N, Index) else No_Node);

   function Member_Key
     (Doc : Document; N : Node_Ref; Index : Positive) return Byte_Array
   is
      M : constant Node_Ref := Member (Doc, N, Index);
   begin
      if M = No_Node then
         return [1 .. 0 => 0];
      end if;
      declare
         Nd : Node renames Doc.Nodes (Positive (M));
      begin
         return Doc.Pool (Nd.Key_Start .. Nd.Key_Start + Nd.Key_Len - 1);
      end;
   end Member_Key;

   function Find
     (Doc : Document; N : Node_Ref; Key : Byte_Array) return Node_Ref
   is
      Cur : Node_Ref;
   begin
      if N = No_Node or else Doc.Nodes (Positive (N)).Kind /= Object_Node then
         return No_Node;
      end if;
      Cur := Doc.Nodes (Positive (N)).First_Child;
      while Cur /= No_Node loop
         declare
            Nd : Node renames Doc.Nodes (Positive (Cur));
         begin
            if Nd.Key_Len = Key'Length
              and then Doc.Pool (Nd.Key_Start .. Nd.Key_Start + Nd.Key_Len - 1)
                       = Key
            then
               return Cur;
            end if;
            Cur := Nd.Next_Sibling;
         end;
      end loop;
      return No_Node;
   end Find;

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   --  Exact-value equality of two number nodes: normalize both via the exact
   --  decimal parser and compare sign/significand/exponent (the normalized form
   --  is unique per value, so 1 and 1.0 match). Fall back to text equality when
   --  either lies outside the exact-decimal range.
   function Numbers_Equal
     (A_Doc : Document; A : Node_Ref;
      B_Doc : Document; B : Node_Ref) return Boolean
   is
      use Representation.Decimals;
      TA : constant Byte_Array := Text (A_Doc, A);
      TB : constant Byte_Array := Text (B_Doc, B);
      DA, DB : Decimal;
      OA, OB : Parse_Outcome;
   begin
      Parse (To_String (TA), DA, OA);
      Parse (To_String (TB), DB, OB);
      if OA = Decimal_Ok and then OB = Decimal_Ok then
         if Is_Zero (DA) or else Is_Zero (DB) then
            return Is_Zero (DA) and then Is_Zero (DB);
         end if;
         return Is_Negative (DA) = Is_Negative (DB)
           and then Significand (DA) = Significand (DB)
           and then Exponent (DA) = Exponent (DB);
      end if;
      return TA = TB;
   end Numbers_Equal;

   function Equal
     (A_Doc : Document; A : Node_Ref;
      B_Doc : Document; B : Node_Ref) return Boolean
   is
      KA : constant Node_Kind := Kind (A_Doc, A);
   begin
      if KA /= Kind (B_Doc, B) then
         return False;
      end if;
      case KA is
         when Null_Node =>
            return True;
         when Bool_Node =>
            return Bool_Value (A_Doc, A) = Bool_Value (B_Doc, B);
         when Number_Node =>
            return Numbers_Equal (A_Doc, A, B_Doc, B);
         when String_Node =>
            return Text (A_Doc, A) = Text (B_Doc, B);
         when Array_Node =>
            if Length (A_Doc, A) /= Length (B_Doc, B) then
               return False;
            end if;
            for I in 1 .. Length (A_Doc, A) loop
               if not Equal (A_Doc, Element (A_Doc, A, I),
                             B_Doc, Element (B_Doc, B, I))
               then
                  return False;
               end if;
            end loop;
            return True;
         when Object_Node =>
            if Length (A_Doc, A) /= Length (B_Doc, B) then
               return False;
            end if;
            for I in 1 .. Length (A_Doc, A) loop
               declare
                  Key : constant Byte_Array := Member_Key (A_Doc, A, I);
                  MB  : constant Node_Ref := Find (B_Doc, B, Key);
               begin
                  if MB = No_Node
                    or else not Equal (A_Doc, Member (A_Doc, A, I), B_Doc, MB)
                  then
                     return False;
                  end if;
               end;
            end loop;
            return True;
      end case;
   end Equal;

end Representation.Documents;
