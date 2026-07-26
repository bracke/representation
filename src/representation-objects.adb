with Representation.Identifiers;

package body Representation.Objects is

   package DM renames Representation.Documents;
   package FLD renames Representation.Fields;
   package Ids renames Representation.Identifiers;
   package Err renames Representation.Errors;
   use type FLD.Presence_Policy;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function Lookup
     (Doc   : DM.Document;
      Obj   : DM.Node_Ref;
      Field : FLD.Field_Descriptor) return DM.Node_Ref is
   begin
      for M in 1 .. DM.Length (Doc, Obj) loop
         if FLD.Matches (Field, DM.Member_Key (Doc, Obj, M)) then
            return DM.Member (Doc, Obj, M);
         end if;
      end loop;
      return DM.No_Node;
   end Lookup;

   procedure Validate
     (Doc      : DM.Document;
      Obj      : DM.Node_Ref;
      Contract : Field_Set;
      Policy   : Unknown_Policy;
      Status   : out Object_Status)
   is
      Seen : array (Contract'Range) of Boolean := [others => False];

      procedure Fail (Id : String; Cat : Err.Error_Category) is
         N : constant Natural :=
           (if Id'Length > Max_Error_Id then Max_Error_Id else Id'Length);
      begin
         Status.Ok        := False;
         Status.Category  := Cat;
         Status.Error_Buf := [others => ' '];
         Status.Error_Buf (1 .. N) := Id (Id'First .. Id'First + N - 1);
         Status.Error_Len := N;
      end Fail;

   begin
      Status := (Ok => True, Category => Err.Ok, others => <>);

      for M in 1 .. DM.Length (Doc, Obj) loop
         declare
            Key     : constant Byte_Array := DM.Member_Key (Doc, Obj, M);
            Matched : Natural := 0;
         begin
            for F in Contract'Range loop
               if FLD.Matches (Contract (F), Key) then
                  Matched := F;
                  exit;
               end if;
            end loop;

            if Matched = 0 then
               if Policy = Reject then
                  Fail (Err.Object_Unknown_Field, Err.Structural_Error);
                  return;
               end if;
            elsif Seen (Matched) then
               --  The same field supplied twice (repeat, or canonical + alias).
               Fail (Err.Object_Duplicate_Field, Err.Structural_Error);
               return;
            else
               Seen (Matched) := True;
            end if;
         end;
      end loop;

      for F in Contract'Range loop
         if FLD.Presence (Contract (F)) = FLD.Required and then not Seen (F) then
            Fail (Err.Object_Missing_Field, Err.Structural_Error);
            return;
         end if;
      end loop;
   end Validate;

   function New_Object (Doc : in out DM.Document) return DM.Node_Ref is
     (DM.Add_Object (Doc));

   procedure Put_Field
     (Doc   : in out DM.Document;
      Obj   : DM.Node_Ref;
      Field : FLD.Field_Descriptor;
      Value : DM.Node_Ref) is
   begin
      DM.Insert (Doc, Obj, To_Bytes (Ids.Image (FLD.Canonical (Field))), Value);
   end Put_Field;

end Representation.Objects;
