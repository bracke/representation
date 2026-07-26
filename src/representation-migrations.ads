--  Representation.Migrations — deterministic version migrations (§36). A
--  migration set is a caller-owned collection of steps, each an upgrade from one
--  version to the next carrying a Transform that rewrites the document value.
--  At most one step may leave any version, so the upgrade path between two
--  versions is unique — migration is deterministic (REP-INV-014). Steps are
--  forward-only (To > From), so a chain strictly increases and always
--  terminates. Planning and applying report a path's absence rather than
--  guessing, and never fabricate a downgrade.
with Representation.Version;
with Representation.Documents;
package Representation.Migrations is

   subtype Version_Number is Representation.Version.Version_Number;

   --  Rewrite a document value from one version to its successor. Root may be
   --  replaced. Ok is False on a representation-level failure that aborts the
   --  chain.
   type Transform is access procedure
     (Doc  : in out Representation.Documents.Document;
      Root : in out Representation.Documents.Node_Ref;
      Ok   : out Boolean);

   type Migration_Set (Capacity : Natural) is limited private;

   procedure Start (MS : in out Migration_Set);

   --  Register the step From_Version -> To_Version. Added is False if the set is
   --  final or full, if To_Version <= From_Version (forward-only), or if a step
   --  already leaves From_Version (determinism — REP-INV-014).
   procedure Add_Step
     (MS           : in out Migration_Set;
      From_Version : Version_Number;
      To_Version   : Version_Number;
      Apply        : Transform;
      Added        : out Boolean);

   procedure Finalize (MS : in out Migration_Set);
   function Is_Final (MS : Migration_Set) return Boolean;
   function Step_Count (MS : Migration_Set) return Natural;

   type Plan_Status is (Plan_Ok, Plan_No_Path, Plan_Cycle);

   --  Is there a deterministic chain From_Version -> To_Version? (No document is
   --  touched.)
   function Plan
     (MS           : Migration_Set;
      From_Version : Version_Number;
      To_Version   : Version_Number) return Plan_Status;

   type Migrate_Status is
     (Migrate_Ok, Migrate_No_Path, Migrate_Cycle, Migrate_Failed);

   --  Apply the chain From_Version -> To_Version to (Doc, Root) in order.
   procedure Migrate
     (MS           : Migration_Set;
      Doc          : in out Representation.Documents.Document;
      Root         : in out Representation.Documents.Node_Ref;
      From_Version : Version_Number;
      To_Version   : Version_Number;
      Status       : out Migrate_Status);

private

   type Step is record
      From_V : Version_Number := Version_Number'First;
      To_V   : Version_Number := Version_Number'First;
      Apply  : Transform := null;
   end record;

   type Step_Array is array (Positive range <>) of Step;

   type Migration_Set (Capacity : Natural) is limited record
      Steps : Step_Array (1 .. Capacity);
      N     : Natural := 0;
      Final : Boolean := False;
   end record;

end Representation.Migrations;
