with Ada.Command_Line;
with Ada.Directories;
with Ada.Text_IO;

with GNAT.OS_Lib;

with Project_Tools.Files;
with Project_Tools.Processes;
with Project_Tools.Release_Checks;

--  Release and documentation guard for the representation library. Written
--  entirely in Ada (§5): the dependency-boundary audit scans the core sources
--  directly rather than shelling out. Modes:
--
--    (default)          required-surface + text + dependency-boundary audit
--    --release          + build library, build/run tests, build/run examples
--    --release-strict   + require clean git worktrees (representation, project_tools)
procedure Check_Representation is

   use Ada.Text_IO;
   package Files renames Project_Tools.Files;
   package Proc renames Project_Tools.Processes;
   package RC renames Project_Tools.Release_Checks;

   Errors : Natural := 0;

   procedure Fail (Message : String) is
   begin
      Errors := Errors + 1;
      Put_Line (Standard_Error, "error: " & Message);
   end Fail;

   function Root return String is
      Current : constant String := Ada.Directories.Current_Directory;
      Found   : constant String :=
        Files.Find_Root_Upward (Current, "representation.gpr");
   begin
      if Found = "" then
         Put_Line
           (Standard_Error, "representation root not found from " & Current);
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
         raise Program_Error;
      end if;
      return Found;
   end Root;

   The_Root : constant String := Root;

   procedure Need_File (Relative : String) is
   begin
      if not Files.File_Exists (The_Root & "/" & Relative) then
         Fail ("missing required file: " & Relative);
      end if;
   end Need_File;

   procedure Need_Directory (Relative : String) is
   begin
      if not Files.Directory_Exists (The_Root & "/" & Relative) then
         Fail ("missing required directory: " & Relative);
      end if;
   end Need_Directory;

   procedure Need_Text (Relative : String; Pattern : String) is
   begin
      if not Files.File_Contains (The_Root & "/" & Relative, Pattern) then
         Fail (Relative & " must contain: " & Pattern);
      end if;
   end Need_Text;

   function Run
     (Label   : String;
      Dir     : String;
      Program : String;
      Args    : GNAT.OS_Lib.Argument_List) return Boolean
   is
      Status : Integer;
   begin
      if Program = "" then
         Fail (Label & ": program not found");
         return False;
      end if;
      Status :=
        Proc.Run_Status
          (Label => Label, Dir => Dir, Program => Program, Args => Args);
      if Status /= 0 then
         Fail (Label & " failed (status" & Integer'Image (Status) & ")");
         return False;
      end if;
      return True;
   end Run;

   Ignored : Boolean;
   pragma Unreferenced (Ignored);

   ---------------------------------------------------------------------------
   --  Required release surface
   ---------------------------------------------------------------------------

   procedure Check_Surface is
   begin
      Need_Directory ("src");
      Need_Directory ("tests/representation_tests");
      Need_Directory ("examples/representation_examples");
      Need_Directory ("tools");
      Need_Directory ("docs");
      Need_Directory ("docs/ai");
      Need_Directory ("docs/adr");
      Need_Directory ("fuzz");
      Need_Directory ("fixtures");
      Need_Directory ("invariant-registry");

      Need_File ("alire.toml");
      Need_File ("representation.gpr");
      Need_File ("README.md");
      Need_File ("LICENSE");
      Need_File ("CHANGELOG.md");
      Need_File ("AI.md");
      Need_File ("SECURITY.md");
      Need_File ("CONTRIBUTING.md");
      Need_File ("tests/representation_tests/alire.toml");
      Need_File ("examples/representation_examples/alire.toml");
      Need_File ("examples/representation_examples/src/quickstart.adb");

      Need_File ("docs/QUICKSTART.md");
      Need_File ("docs/ARCHITECTURE.md");
      Need_File ("docs/RELEASE.md");
      Need_File ("docs/PHASE_STATUS.md");
      Need_File ("docs/ai/invariants.md");
      Need_File ("docs/ai/package_map.md");
      Need_File ("docs/ai/prohibited_patterns.md");
      Need_File ("docs/ai/allowed_dependencies.md");
      Need_File ("docs/adr/README.md");

      Need_Text ("alire.toml", "gnat_native = ""=15.2.1""");
      Need_Text ("README.md", "representation");
      Need_Text ("docs/ai/invariants.md", "REP-INV-020");
   end Check_Surface;

   ---------------------------------------------------------------------------
   --  Dependency-boundary audit (always), in Ada: the core must not depend on
   --  any ecosystem or transport package.
   ---------------------------------------------------------------------------

   procedure Check_File (Full : String; Name : String) is
      procedure Forbid (Pkg : String) is
      begin
         if Files.File_Contains (Full, "with " & Pkg) then
            Fail (Name & ": forbidden dependency 'with " & Pkg & "'");
         end if;
      end Forbid;
   begin
      Forbid ("Web");
      Forbid ("Database");
      Forbid ("Tables");
      Forbid ("Validation");
      Forbid ("Identity");
      Forbid ("Authorization");
      Forbid ("Jobs");
      Forbid ("Notifications");
      Forbid ("Audit");
      Forbid ("Templates");
      Forbid ("Forms");
      Forbid ("I18n");
      Forbid ("Messages");
      Forbid ("Httpclient");
      Forbid ("GNAT.Sockets");
      Forbid ("AWS");
   end Check_File;

   procedure Check_Dependency_Boundary is
      Search : Ada.Directories.Search_Type;
      Item   : Ada.Directories.Directory_Entry_Type;
      Src    : constant String := The_Root & "/src";
   begin
      Ada.Directories.Start_Search
        (Search, Src, "*.ad*",
         Filter => [Ada.Directories.Ordinary_File => True, others => False]);
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Item);
         Check_File
           (Ada.Directories.Full_Name (Item),
            Ada.Directories.Simple_Name (Item));
      end loop;
      Ada.Directories.End_Search (Search);
   end Check_Dependency_Boundary;

   ---------------------------------------------------------------------------
   --  Build / test / example (release mode)
   ---------------------------------------------------------------------------

   procedure Check_Build_And_Test is
      Alr : constant String := Proc.Locate_Command ("alr");

      Tests_Dir : constant String := The_Root & "/tests/representation_tests";
      Ex_Dir    : constant String := The_Root & "/examples/representation_examples";
      No_Args   : constant GNAT.OS_Lib.Argument_List := [];
   begin
      if not Run ("build library", The_Root, Alr,
                  [new String'("--non-interactive"), new String'("build")])
      then
         return;
      end if;
      if Run ("build tests", Tests_Dir, Alr,
              [new String'("--non-interactive"), new String'("build")])
      then
         Ignored := Run ("run tests", Tests_Dir, Tests_Dir & "/bin/tests", No_Args);
      end if;
      if Run ("build example", Ex_Dir, Alr,
              [new String'("--non-interactive"), new String'("build")])
      then
         Ignored :=
           Run ("run example", Ex_Dir, Ex_Dir & "/bin/quickstart", No_Args);
      end if;
   end Check_Build_And_Test;

   procedure Check_Clean_Worktree (Label : String; Path : String) is
   begin
      RC.Require_Clean_Git_Worktree (Label => Label, Path => Path, Quiet => True);
   exception
      when Program_Error =>
         Fail (Label & " worktree must be clean for --release-strict");
   end Check_Clean_Worktree;

begin
   Check_Surface;
   Check_Dependency_Boundary;

   declare
      Stale_Docs : constant String :=
        Project_Tools.Release_Checks.Stale_Doc_Scaffolding (The_Root);
   begin
      if Stale_Docs /= "" then
         Fail ("docs carry stale scaffolding -- describe current state, not a "
               & "future phase:" & ASCII.LF & Stale_Docs);
      end if;
   end;

   if Proc.Has_Argument ("--release")
     or else Proc.Has_Argument ("--release-strict")
   then
      Check_Build_And_Test;
   end if;

   if Proc.Has_Argument ("--release-strict") then
      Check_Clean_Worktree ("representation", The_Root);
      Check_Clean_Worktree ("project_tools", The_Root & "/../../project_tools");
   end if;

   if Errors = 0 then
      Put_Line ("check_representation: all checks passed");
   else
      Put_Line
        (Standard_Error,
         "check_representation:" & Natural'Image (Errors) & " error(s)");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Check_Representation;
