--  migrate — upgrade a document from an older contract version to the current
--  one through a deterministic migration chain. Each step rewrites the document
--  value; the path between versions is unique (REP-INV-014).
with Ada.Text_IO; use Ada.Text_IO;

with Representation;             use Representation;
with Representation.Buffers;
with Representation.Documents;
with Representation.Versions;
with Representation.Migrations;
with Representation.JSON.Documents;
with Migrate_Steps;

procedure Migrate is

   package DM renames Representation.Documents;
   package Ver renames Representation.Versions;
   package Mig renames Representation.Migrations;

   function Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

   function Str (B : Byte_Array) return String is
      R : String (1 .. B'Length);
   begin
      for I in B'Range loop
         R (I - B'First + 1) := Character'Val (Natural (B (I)));
      end loop;
      return R;
   end Str;

   Doc   : DM.Document (256, 4096);
   Root  : DM.Node_Ref;
   VS    : Ver.Version_Set (8);
   MS    : Mig.Migration_Set (8);
   Added : Boolean;
   St    : Mig.Migrate_Status;

   Buf   : aliased Representation.Buffers.Buffer (4096);
   Snk   : Representation.Buffers.Buffer_Sink (Buf'Access);
   ER    : Representation.JSON.Documents.Encode_Result;
begin
   --  Supported versions: current is 3; 1 and 2 are accepted via migration.
   Ver.Start (VS, Current => 3);
   Ver.Add_Supported (VS, 1, Added);
   Ver.Add_Supported (VS, 2, Added);
   Ver.Finalize (VS);

   Mig.Start (MS);
   Mig.Add_Step (MS, 1, 2, Migrate_Steps.Add_Active'Access, Added);
   Mig.Add_Step (MS, 2, 3, Migrate_Steps.Add_Role'Access, Added);
   Mig.Finalize (MS);

   --  A v1 payload.
   Root := DM.Add_Object (Doc);
   DM.Insert (Doc, Root, Bytes ("id"), DM.Add_Number (Doc, Bytes ("7")));

   Put_Line ("incoming version 1 resolves to: "
             & Ver.Resolution'Image (Ver.Resolve (VS, 1)));

   Mig.Migrate (MS, Doc, Root, From_Version => 1, To_Version => Ver.Current (VS),
                Status => St);
   Put_Line ("migrate status: " & Mig.Migrate_Status'Image (St));

   Representation.JSON.Documents.Encode
     (Doc, Root, Snk, Representation.JSON.Documents.Canonical, ER);
   Put_Line ("migrated v3:    "
             & Str (Representation.Buffers.To_Byte_Array (Buf)));
end Migrate;
