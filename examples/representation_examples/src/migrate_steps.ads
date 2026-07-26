--  Migration transforms for the `migrate` example. They live at library level
--  so their 'Access is valid for Representation.Migrations.Transform (a nested
--  subprogram would be too deep for the access type).
with Representation.Documents;
package Migrate_Steps is

   --  v1 -> v2 : add "active" (default true) if missing.
   procedure Add_Active
     (Doc  : in out Representation.Documents.Document;
      Root : in out Representation.Documents.Node_Ref;
      Ok   : out Boolean);

   --  v2 -> v3 : add "role" (default "user") if missing.
   procedure Add_Role
     (Doc  : in out Representation.Documents.Document;
      Root : in out Representation.Documents.Node_Ref;
      Ok   : out Boolean);

end Migrate_Steps;
