with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Documents;
with Representation.Metadata;
with Representation.Links;
with Representation.Pagination;

package body Models_Tests is

   package DM renames Representation.Documents;
   package MD renames Representation.Metadata;
   package LK renames Representation.Links;
   package PG renames Representation.Pagination;
   use type DM.Node_Ref;
   use type DM.Node_Kind;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function To_Str (B : Byte_Array) return String is
      R : String (1 .. B'Length);
   begin
      for I in B'Range loop
         R (I - B'First + 1) := Character'Val (Natural (B (I)));
      end loop;
      return R;
   end To_Str;

   procedure Test_Metadata (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc   : DM.Document (32, 256);
      M     : MD.Meta (4, 64);
      Added : Boolean;
      Obj   : DM.Node_Ref;
      M2    : MD.Meta (4, 64);
   begin
      MD.Add (M, To_Bytes ("trace"),
              DM.Add_String (Doc, To_Bytes ("abc")), Added);
      Assert (Added, "add trace");
      MD.Add (M, To_Bytes ("count"), DM.Add_Number (Doc, To_Bytes ("2")), Added);
      Assert (Added and then MD.Count (M) = 2, "two entries");
      MD.Add (M, To_Bytes ("trace"), DM.Add_Null (Doc), Added);
      Assert (not Added, "duplicate key refused");
      Assert (MD.Has (M, To_Bytes ("count")), "has count");
      Assert (MD.Get (M, To_Bytes ("missing")) = DM.No_Node, "absent -> No_Node");

      Obj := MD.To_Object (M, Doc);
      Assert (DM.Length (Doc, Obj) = 2, "object has two members");
      Assert (To_Str (DM.Text (Doc, DM.Find (Doc, Obj, To_Bytes ("trace"))))
              = "abc", "member value");

      MD.From_Object (M2, Doc, Obj);
      Assert (MD.Count (M2) = 2 and then MD.Has (M2, To_Bytes ("trace")),
              "round-trips through a document object");
   end Test_Metadata;

   procedure Test_Links (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc   : DM.Document (32, 256);
      L     : LK.Link_Set (4, 128);
      Added : Boolean;
      Obj   : DM.Node_Ref;
      L2    : LK.Link_Set (4, 128);
   begin
      LK.Add (L, To_Bytes ("self"), To_Bytes ("/users/7"), Added);
      Assert (Added, "add self");
      LK.Add (L, To_Bytes ("next"), To_Bytes ("/users?page=2"), Added);
      Assert (Added and then LK.Count (L) = 2, "two links");
      LK.Add (L, To_Bytes ("self"), To_Bytes ("/x"), Added);
      Assert (not Added, "duplicate relation refused");
      Assert (To_Str (LK.Href (L, To_Bytes ("self"))) = "/users/7", "href lookup");

      Obj := LK.To_Object (L, Doc);
      Assert (DM.Kind (Doc, Obj) = DM.Object_Node
              and then DM.Length (Doc, Obj) = 2, "object of links");

      LK.From_Object (L2, Doc, Obj);
      Assert (LK.Count (L2) = 2
              and then To_Str (LK.Href (L2, To_Bytes ("next"))) = "/users?page=2",
              "links round-trip");
   end Test_Links;

   procedure Test_Pagination (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (32, 256);
      P    : PG.Page :=
        PG.Make (Limit => 20, Offset => 40, Total => 137, Has_More => True);
      Obj  : DM.Node_Ref;
      P2   : PG.Page;
      Ok   : Boolean;
   begin
      PG.Set_Cursor (P, To_Bytes ("eyJpZCI6N30"), Ok);
      Assert (Ok, "cursor set");

      Obj := PG.To_Object (P, Doc);
      Assert (To_Str (DM.Text (Doc, DM.Find (Doc, Obj, To_Bytes ("total"))))
              = "137", "total member");

      PG.From_Object (Doc, Obj, P2, Ok);
      Assert (Ok, "reads back");
      Assert (PG.Limit (P2) = 20 and then PG.Offset (P2) = 40
              and then PG.Total (P2) = 137 and then PG.Has_More (P2),
              "numeric fields round-trip");
      Assert (To_Str (PG.Cursor (P2)) = "eyJpZCI6N30", "cursor round-trips");

      --  A wrong-typed member is reported.
      declare
         Bad : constant DM.Node_Ref := DM.Add_Object (Doc);
         P3  : PG.Page;
         Ok3 : Boolean;
      begin
         DM.Insert (Doc, Bad, To_Bytes ("limit"),
                    DM.Add_String (Doc, To_Bytes ("x")));
         PG.From_Object (Doc, Bad, P3, Ok3);
         Assert (not Ok3, "non-numeric limit rejected");
      end;
   end Test_Pagination;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Models: metadata", Test_Metadata'Access));
      Suite.Add_Test (Caller.Create ("Models: links", Test_Links'Access));
      Suite.Add_Test
        (Caller.Create ("Models: pagination", Test_Pagination'Access));
   end Add_Tests;

end Models_Tests;
