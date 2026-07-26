with Representation.Values;

package body Representation.Schemas is

   package DM renames Representation.Documents;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Err renames Representation.Errors;
   use type DM.Node_Kind;
   use type DM.Node_Ref;

   procedure Start
     (S       : in out Schema;
      Id      : Representation.Identifiers.Schema_Id;
      Unknown : Obj.Unknown_Policy := Obj.Reject) is
   begin
      S.Ident  := Id;
      S.Policy := Unknown;
      S.N      := 0;
      S.Final  := False;
   end Start;

   procedure Add_Field
     (S     : in out Schema;
      Field : FLD.Field_Descriptor;
      Kind  : Type_Kind;
      Added : out Boolean) is
   begin
      if S.Final or else S.N >= S.Capacity then
         Added := False;
         return;
      end if;
      S.N := S.N + 1;
      S.Fields (S.N) := (Descr => Field, Kind => Kind);
      Added := True;
   end Add_Field;

   procedure Finalize (S : in out Schema) is
   begin
      S.Final := True;
   end Finalize;

   function Is_Final (S : Schema) return Boolean is (S.Final);

   function Id (S : Schema) return Representation.Identifiers.Schema_Id is
     (S.Ident);

   function Unknown_Policy (S : Schema) return Obj.Unknown_Policy is (S.Policy);

   function Field_Count (S : Schema) return Natural is (S.N);

   function Field
     (S : Schema; Index : Positive) return FLD.Field_Descriptor is
     (S.Fields (Index).Descr);

   function Field_Type (S : Schema; Index : Positive) return Type_Kind is
     (S.Fields (Index).Kind);

   function Find (S : Schema; Name : Byte_Array) return Natural is
   begin
      for I in 1 .. S.N loop
         if FLD.Matches (S.Fields (I).Descr, Name) then
            return I;
         end if;
      end loop;
      return 0;
   end Find;

   --  Does the value node satisfy the declared type kind?
   function Kind_Matches
     (Doc : DM.Document; N : DM.Node_Ref; Kind : Type_Kind) return Boolean is
   begin
      case Kind is
         when Kind_Any =>
            return N /= DM.No_Node;
         when Kind_Null =>
            return DM.Kind (Doc, N) = DM.Null_Node;
         when Kind_Boolean =>
            return DM.Kind (Doc, N) = DM.Bool_Node;
         when Kind_Number =>
            return DM.Kind (Doc, N) = DM.Number_Node;
         when Kind_Integer =>
            declare
               V  : Long_Long_Integer;
               St : Representation.Values.Value_Status;
               use type Representation.Values.Value_Status;
            begin
               Representation.Values.Get_Integer (Doc, N, V, St);
               return St = Representation.Values.Value_Ok;
            end;
         when Kind_String | Kind_Enum =>
            return DM.Kind (Doc, N) = DM.String_Node;
         when Kind_Reference =>
            return DM.Kind (Doc, N) = DM.String_Node
              and then DM.Text (Doc, N)'Length > 0;
         when Kind_Array =>
            return DM.Kind (Doc, N) = DM.Array_Node;
         when Kind_Object =>
            return DM.Kind (Doc, N) = DM.Object_Node;
      end case;
   end Kind_Matches;

   procedure Validate
     (Doc    : DM.Document;
      Node   : DM.Node_Ref;
      S      : Schema;
      Status : out Schema_Status)
   is
      procedure Set_Err
        (Cat : Err.Error_Category; Id : String; Field_Index : Natural := 0)
      is
         M : constant Natural := (if Id'Length > 64 then 64 else Id'Length);
      begin
         Status.Ok          := False;
         Status.Category    := Cat;
         Status.Field_Index := Field_Index;
         Status.Error_Buf   := [others => ' '];
         Status.Error_Buf (1 .. M) := Id (Id'First .. Id'First + M - 1);
         Status.Error_Len   := M;
      end Set_Err;

      Contract : FLD.Field_Set (1 .. S.N);
      OS       : Obj.Object_Status;
   begin
      Status := (Ok => True, Category => Err.Ok, others => <>);

      if DM.Kind (Doc, Node) /= DM.Object_Node then
         Set_Err (Err.Structural_Error, Err.Field_Type_Mismatch);
         return;
      end if;

      for I in 1 .. S.N loop
         Contract (I) := S.Fields (I).Descr;
      end loop;

      Obj.Validate (Doc, Node, Contract, S.Policy, OS);
      if not OS.Ok then
         Set_Err (OS.Category, Obj.Error_Id (OS));
         return;
      end if;

      --  Type-check every present field.
      for I in 1 .. S.N loop
         declare
            V : constant DM.Node_Ref :=
              Obj.Lookup (Doc, Node, S.Fields (I).Descr);
         begin
            if V /= DM.No_Node
              and then not Kind_Matches (Doc, V, S.Fields (I).Kind)
            then
               Set_Err (Err.Representation_Constraint,
                        Err.Field_Type_Mismatch, I);
               return;
            end if;
         end;
      end loop;
   end Validate;

end Representation.Schemas;
