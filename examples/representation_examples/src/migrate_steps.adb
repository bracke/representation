with Representation; use Representation;

package body Migrate_Steps is

   package DM renames Representation.Documents;
   use type DM.Node_Ref;

   function Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Bytes;

   procedure Add_Active
     (Doc  : in out DM.Document;
      Root : in out DM.Node_Ref;
      Ok   : out Boolean) is
   begin
      if DM.Find (Doc, Root, Bytes ("active")) = DM.No_Node then
         DM.Insert (Doc, Root, Bytes ("active"), DM.Add_Bool (Doc, True));
      end if;
      Ok := not DM.Overflowed (Doc);
   end Add_Active;

   procedure Add_Role
     (Doc  : in out DM.Document;
      Root : in out DM.Node_Ref;
      Ok   : out Boolean) is
   begin
      if DM.Find (Doc, Root, Bytes ("role")) = DM.No_Node then
         DM.Insert (Doc, Root, Bytes ("role"),
                    DM.Add_String (Doc, Bytes ("user")));
      end if;
      Ok := not DM.Overflowed (Doc);
   end Add_Role;

end Migrate_Steps;
