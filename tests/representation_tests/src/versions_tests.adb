with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Documents;
with Representation.Versions;
with Representation.Migrations;

package body Versions_Tests is

   package DM renames Representation.Documents;
   package Ver renames Representation.Versions;
   package Mig renames Representation.Migrations;
   use type DM.Node_Ref;
   use type DM.Node_Kind;
   use type Ver.Resolution;
   use type Mig.Plan_Status;
   use type Mig.Migrate_Status;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   --  Migration transforms (library-level, so 'Access matches Mig.Transform).
   procedure Add_Active
     (Doc : in out DM.Document; Root : in out DM.Node_Ref; Ok : out Boolean) is
   begin
      if DM.Kind (Doc, Root) = DM.Object_Node
        and then DM.Find (Doc, Root, To_Bytes ("active")) = DM.No_Node
      then
         DM.Insert (Doc, Root, To_Bytes ("active"), DM.Add_Bool (Doc, False));
      end if;
      Ok := not DM.Overflowed (Doc);
   end Add_Active;

   procedure Add_Role
     (Doc : in out DM.Document; Root : in out DM.Node_Ref; Ok : out Boolean) is
   begin
      if DM.Kind (Doc, Root) = DM.Object_Node
        and then DM.Find (Doc, Root, To_Bytes ("role")) = DM.No_Node
      then
         DM.Insert (Doc, Root, To_Bytes ("role"),
                    DM.Add_String (Doc, To_Bytes ("user")));
      end if;
      Ok := not DM.Overflowed (Doc);
   end Add_Role;

   procedure Fail_Step
     (Doc : in out DM.Document; Root : in out DM.Node_Ref; Ok : out Boolean) is
      pragma Unreferenced (Doc, Root);
   begin
      Ok := False;
   end Fail_Step;

   procedure Test_Resolve (T : in out Fixture) is
      pragma Unreferenced (T);
      VS    : Ver.Version_Set (8);
      Added : Boolean;
   begin
      Ver.Start (VS, Current => 5);
      Ver.Add_Supported (VS, 2, Added);
      Ver.Add_Supported (VS, 3, Added);
      Ver.Add_Supported (VS, 7, Added);   --  >= Current: refused
      Assert (not Added, "cannot add a version at/after Current");
      Ver.Finalize (VS);

      Assert (Ver.Resolve (VS, 5) = Ver.Version_Current, "current");
      Assert (Ver.Resolve (VS, 3) = Ver.Version_Migratable, "older supported");
      Assert (Ver.Resolve (VS, 6) = Ver.Version_Too_New,
              "newer than current is never downgraded");
      Assert (Ver.Resolve (VS, 4) = Ver.Version_Unsupported,
              "older but unregistered is unsupported");
   end Test_Resolve;

   procedure Test_Version_Immutable (T : in out Fixture) is
      pragma Unreferenced (T);
      VS    : Ver.Version_Set (8);
      Added : Boolean;
   begin
      Ver.Start (VS, Current => 3);
      Ver.Add_Supported (VS, 1, Added);
      Ver.Finalize (VS);
      Ver.Add_Supported (VS, 2, Added);
      Assert (not Added, "no additions after finalize");
      Assert (not Ver.Is_Supported (VS, 2), "post-finalize version not added");
   end Test_Version_Immutable;

   procedure Test_Migration_Graph (T : in out Fixture) is
      pragma Unreferenced (T);
      MS    : Mig.Migration_Set (8);
      Added : Boolean;
   begin
      Mig.Start (MS);
      Mig.Add_Step (MS, 1, 2, Add_Active'Access, Added);
      Assert (Added, "step 1->2");
      Mig.Add_Step (MS, 2, 3, Add_Role'Access, Added);
      Assert (Added, "step 2->3");
      --  A second edge leaving version 1 breaks determinism: refused.
      Mig.Add_Step (MS, 1, 9, Add_Role'Access, Added);
      Assert (not Added and then Mig.Step_Count (MS) = 2,
              "at most one step per source version (REP-INV-014)");
      --  Backward steps are refused.
      Mig.Add_Step (MS, 3, 2, Add_Role'Access, Added);
      Assert (not Added, "forward-only steps");
      Mig.Finalize (MS);

      Assert (Mig.Plan (MS, 1, 3) = Mig.Plan_Ok, "path 1->3 exists");
      Assert (Mig.Plan (MS, 2, 2) = Mig.Plan_Ok, "empty path");
      Assert (Mig.Plan (MS, 3, 1) = Mig.Plan_No_Path, "no downgrade path");
      Assert (Mig.Plan (MS, 1, 5) = Mig.Plan_No_Path, "no path past the chain");
   end Test_Migration_Graph;

   procedure Test_Migrate_Apply (T : in out Fixture) is
      pragma Unreferenced (T);
      MS    : Mig.Migration_Set (8);
      Added : Boolean;
      Doc   : DM.Document (16, 128);
      Root  : DM.Node_Ref;
      St    : Mig.Migrate_Status;
   begin
      Mig.Start (MS);
      Mig.Add_Step (MS, 1, 2, Add_Active'Access, Added);
      Mig.Add_Step (MS, 2, 3, Add_Role'Access, Added);
      Mig.Finalize (MS);

      Root := DM.Add_Object (Doc);
      DM.Insert (Doc, Root, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));

      Mig.Migrate (MS, Doc, Root, 1, 3, St);
      Assert (St = Mig.Migrate_Ok, "chain applied");
      Assert (DM.Find (Doc, Root, To_Bytes ("active")) /= DM.No_Node,
              "1->2 added active");
      Assert (DM.Find (Doc, Root, To_Bytes ("role")) /= DM.No_Node,
              "2->3 added role");
   end Test_Migrate_Apply;

   procedure Test_Migrate_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc   : DM.Document (16, 128);
      Root  : DM.Node_Ref;
      Added : Boolean;
      St    : Mig.Migrate_Status;
   begin
      Root := DM.Add_Object (Doc);

      --  No path.
      declare
         MS : Mig.Migration_Set (8);
      begin
         Mig.Start (MS);
         Mig.Add_Step (MS, 1, 2, Add_Active'Access, Added);
         Mig.Finalize (MS);
         Mig.Migrate (MS, Doc, Root, 1, 5, St);
         Assert (St = Mig.Migrate_No_Path, "no path to 5");
      end;

      --  Failing transform aborts the chain.
      declare
         MS : Mig.Migration_Set (8);
      begin
         Mig.Start (MS);
         Mig.Add_Step (MS, 1, 2, Fail_Step'Access, Added);
         Mig.Finalize (MS);
         Mig.Migrate (MS, Doc, Root, 1, 2, St);
         Assert (St = Mig.Migrate_Failed, "failing step reported");
      end;
   end Test_Migrate_Errors;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Versions: resolve", Test_Resolve'Access));
      Suite.Add_Test
        (Caller.Create ("Versions: immutable", Test_Version_Immutable'Access));
      Suite.Add_Test
        (Caller.Create ("Migrations: graph", Test_Migration_Graph'Access));
      Suite.Add_Test
        (Caller.Create ("Migrations: apply chain", Test_Migrate_Apply'Access));
      Suite.Add_Test
        (Caller.Create ("Migrations: errors", Test_Migrate_Errors'Access));
   end Add_Tests;

end Versions_Tests;
