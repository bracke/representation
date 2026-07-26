with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;            use Representation;
with Representation.Documents;

package body Documents_Tests is

   package D renames Representation.Documents;
   use type D.Node_Kind;
   use type D.Node_Ref;

   function B (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end B;

   function S (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end S;

   procedure Test_Scalars (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : D.Document (16, 64);
      N   : D.Node_Ref;
   begin
      N := D.Add_Null (Doc);
      Assert (D.Kind (Doc, N) = D.Null_Node, "null node");
      N := D.Add_Bool (Doc, True);
      Assert (D.Kind (Doc, N) = D.Bool_Node and then D.Bool_Value (Doc, N),
              "bool node");
      N := D.Add_Number (Doc, B ("-3.5"));
      Assert (D.Kind (Doc, N) = D.Number_Node and then S (D.Text (Doc, N)) = "-3.5",
              "number node text");
      N := D.Add_String (Doc, B ("hello"));
      Assert (D.Kind (Doc, N) = D.String_Node
              and then S (D.Text (Doc, N)) = "hello", "string node text");
      Assert (not D.Overflowed (Doc), "no overflow");
   end Test_Scalars;

   procedure Test_Array (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : D.Document (16, 64);
      Arr : D.Node_Ref;
   begin
      Arr := D.Add_Array (Doc);
      D.Append (Doc, Arr, D.Add_Number (Doc, B ("1")));
      D.Append (Doc, Arr, D.Add_Number (Doc, B ("2")));
      D.Append (Doc, Arr, D.Add_String (Doc, B ("x")));
      D.Set_Root (Doc, Arr);
      Assert (D.Length (Doc, Arr) = 3, "three elements");
      Assert (S (D.Text (Doc, D.Element (Doc, Arr, 1))) = "1", "elem 1");
      Assert (S (D.Text (Doc, D.Element (Doc, Arr, 3))) = "x", "elem 3");
      Assert (D.Element (Doc, Arr, 4) = D.No_Node, "out of range");
      Assert (D.Root (Doc) = Arr, "root set");
   end Test_Array;

   procedure Test_Object (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : D.Document (16, 128);
      Obj : D.Node_Ref;
   begin
      Obj := D.Add_Object (Doc);
      D.Insert (Doc, Obj, B ("a"), D.Add_Number (Doc, B ("1")));
      D.Insert (Doc, Obj, B ("b"), D.Add_Bool (Doc, False));
      Assert (D.Length (Doc, Obj) = 2, "two members");
      Assert (S (D.Member_Key (Doc, Obj, 1)) = "a", "first key");
      Assert (D.Kind (Doc, D.Find (Doc, Obj, B ("b"))) = D.Bool_Node,
              "find by key");
      Assert (D.Find (Doc, Obj, B ("z")) = D.No_Node, "missing key");
   end Test_Object;

   procedure Test_Nested (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : D.Document (32, 128);
      Root : D.Node_Ref;
      Arr  : D.Node_Ref;
      Sub  : D.Node_Ref;
   begin
      Root := D.Add_Object (Doc);
      Arr  := D.Add_Array (Doc);
      Sub  := D.Add_Object (Doc);
      D.Insert (Doc, Sub, B ("k"), D.Add_Bool (Doc, True));
      D.Append (Doc, Arr, D.Add_Number (Doc, B ("1")));
      D.Append (Doc, Arr, Sub);
      D.Insert (Doc, Root, B ("items"), Arr);
      D.Set_Root (Doc, Root);

      declare
         Items : constant D.Node_Ref := D.Find (Doc, Root, B ("items"));
         Inner : constant D.Node_Ref := D.Element (Doc, Items, 2);
      begin
         Assert (D.Kind (Doc, Items) = D.Array_Node, "items is array");
         Assert (D.Length (Doc, Items) = 2, "two items");
         Assert (D.Kind (Doc, Inner) = D.Object_Node, "second item object");
         Assert (D.Bool_Value (Doc, D.Find (Doc, Inner, B ("k"))),
                 "nested member reachable");
      end;
   end Test_Nested;

   --  Build {"a":1,"b":[true,null]} into Doc rooted at the returned object.
   function Build_Sample
     (Doc : in out D.Document; Order_BA : Boolean) return D.Node_Ref
   is
      Obj : constant D.Node_Ref := D.Add_Object (Doc);
      Arr : constant D.Node_Ref := D.Add_Array (Doc);
   begin
      D.Append (Doc, Arr, D.Add_Bool (Doc, True));
      D.Append (Doc, Arr, D.Add_Null (Doc));
      if Order_BA then
         D.Insert (Doc, Obj, B ("b"), Arr);
         D.Insert (Doc, Obj, B ("a"), D.Add_Number (Doc, B ("1")));
      else
         D.Insert (Doc, Obj, B ("a"), D.Add_Number (Doc, B ("1")));
         D.Insert (Doc, Obj, B ("b"), Arr);
      end if;
      return Obj;
   end Build_Sample;

   procedure Test_Equality (T : in out Fixture) is
      pragma Unreferenced (T);
      DA : D.Document (32, 128);
      DB : D.Document (32, 128);
      DC : D.Document (32, 128);
      NA : constant D.Node_Ref := Build_Sample (DA, Order_BA => False);
      NB : constant D.Node_Ref := Build_Sample (DB, Order_BA => True);
      --  Different: array with an extra element.
      OC  : constant D.Node_Ref := D.Add_Object (DC);
      Arr : constant D.Node_Ref := D.Add_Array (DC);
   begin
      --  Member order must not affect object equality.
      Assert (D.Equal (DA, NA, DB, NB), "objects equal regardless of key order");

      D.Append (DC, Arr, D.Add_Bool (DC, True));
      D.Insert (DC, OC, B ("a"), D.Add_Number (DC, B ("1")));
      D.Insert (DC, OC, B ("b"), Arr);
      Assert (not D.Equal (DA, NA, DC, OC), "differing array length not equal");
   end Test_Equality;

   procedure Test_Number_Equality (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : D.Document (16, 64);
      N1  : constant D.Node_Ref := D.Add_Number (Doc, B ("1"));
      N2  : constant D.Node_Ref := D.Add_Number (Doc, B ("1.0"));
      N3  : constant D.Node_Ref := D.Add_Number (Doc, B ("10e-1"));
      N4  : constant D.Node_Ref := D.Add_Number (Doc, B ("2"));
   begin
      Assert (D.Equal (Doc, N1, Doc, N2), "1 = 1.0 by value");
      Assert (D.Equal (Doc, N1, Doc, N3), "1 = 10e-1 by value");
      Assert (not D.Equal (Doc, N1, Doc, N4), "1 /= 2");
   end Test_Number_Equality;

   procedure Test_Overflow (T : in out Fixture) is
      pragma Unreferenced (T);
      Node_Doc : D.Document (2, 64);
      Text_Doc : D.Document (16, 4);
      Arr      : D.Node_Ref;
      N        : D.Node_Ref;
   begin
      Arr := D.Add_Array (Node_Doc);          --  node 1
      N := D.Add_Bool (Node_Doc, True);        --  node 2
      D.Append (Node_Doc, Arr, N);
      N := D.Add_Bool (Node_Doc, True);        --  node 3 -> overflow
      Assert (N = D.No_Node, "third node overflows tiny arena");
      Assert (D.Overflowed (Node_Doc), "node overflow latched");

      N := D.Add_String (Text_Doc, B ("toolong"));  --  7 bytes > 4
      Assert (N = D.No_Node, "string overflows text pool");
      Assert (D.Overflowed (Text_Doc), "text overflow latched");
   end Test_Overflow;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Documents: scalars", Test_Scalars'Access));
      Suite.Add_Test (Caller.Create ("Documents: array", Test_Array'Access));
      Suite.Add_Test (Caller.Create ("Documents: object", Test_Object'Access));
      Suite.Add_Test (Caller.Create ("Documents: nested", Test_Nested'Access));
      Suite.Add_Test
        (Caller.Create ("Documents: equality", Test_Equality'Access));
      Suite.Add_Test
        (Caller.Create ("Documents: number equality",
         Test_Number_Equality'Access));
      Suite.Add_Test
        (Caller.Create ("Documents: overflow", Test_Overflow'Access));
   end Add_Tests;

end Documents_Tests;
