with Representation.Fields;
with Representation.Objects;
with Representation.Identifiers;

package body Representation.Schemas.Diagnostics is

   package DM renames Representation.Documents;
   package D renames Representation.Diagnostics;
   package P renames Representation.Paths;
   package Err renames Representation.Errors;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Ids renames Representation.Identifiers;
   use type DM.Node_Kind;
   use type DM.Node_Ref;
   use type FLD.Presence_Policy;
   use type Obj.Unknown_Policy;

   Max_Value_Chars : constant := 40;

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   function Cap (S : String) return String is
     (if S'Length <= Max_Value_Chars then S
      else S (S'First .. S'First + Max_Value_Chars - 1) & "...");

   function Redacted_Value
     (Doc   : DM.Document;
      N     : DM.Node_Ref;
      Class : Err.Sensitivity_Class) return String is
   begin
      if Err.Is_Redacted (Class) then
         return "<redacted>";
      end if;
      case DM.Kind (Doc, N) is
         when DM.Null_Node =>
            return "null";
         when DM.Bool_Node =>
            return (if DM.Bool_Value (Doc, N) then "true" else "false");
         when DM.Number_Node =>
            return Cap (To_String (DM.Text (Doc, N)));
         when DM.String_Node =>
            return """" & Cap (To_String (DM.Text (Doc, N))) & """";
         when DM.Array_Node =>
            return "<array>";
         when DM.Object_Node =>
            return "<object>";
      end case;
   end Redacted_Value;

   procedure Validate
     (Doc      : DM.Document;
      Node     : DM.Node_Ref;
      S        : Schema;
      Base     : P.Path;
      Into     : in out D.Diagnostic_Set;
      Ok       : out Boolean;
      Capacity : Representation.Field_Count :=
        Representation.Field_Count (D.Max_Entries))
   is
      procedure Add_Diag
        (Category : Err.Error_Category;
         Id       : String;
         Where    : P.Path;
         Message  : String) is
      begin
         D.Add (Into,
                D.Make (Level    => D.Error,
                        Category => Category,
                        Error_Id => Id,
                        Path     => Where,
                        Message  => Message),
                Capacity);
      end Add_Diag;
   begin
      Ok := True;

      if DM.Kind (Doc, Node) /= DM.Object_Node then
         Add_Diag (Err.Structural_Error, Err.Field_Type_Mismatch, Base,
                   "expected object, got "
                   & Redacted_Value (Doc, Node, Err.Public));
         Ok := False;
         return;
      end if;

      --  Presence and type of every declared field.
      for I in 1 .. Field_Count (S) loop
         declare
            F  : constant FLD.Field_Descriptor := Field (S, I);
            V  : constant DM.Node_Ref := Obj.Lookup (Doc, Node, F);
            Pa : P.Path := Base;
         begin
            P.Push_Field (Pa, Ids.Image (FLD.Canonical (F)));
            if V = DM.No_Node then
               if FLD.Presence (F) = FLD.Required then
                  Add_Diag (Err.Structural_Error, Err.Object_Missing_Field, Pa,
                            "required field is missing");
                  Ok := False;
               end if;
            elsif not Accepts (Doc, V, Field_Type (S, I)) then
               Add_Diag
                 (Err.Representation_Constraint, Err.Field_Type_Mismatch, Pa,
                  "expected " & Kind_Name (Field_Type (S, I)) & ", got "
                  & Redacted_Value (Doc, V, FLD.Sensitivity (F)));
               Ok := False;
            end if;
         end;
      end loop;

      --  Undeclared members, when the schema rejects unknowns.
      if Unknown_Policy (S) = Obj.Reject then
         for M in 1 .. DM.Length (Doc, Node) loop
            declare
               Key : constant Byte_Array := DM.Member_Key (Doc, Node, M);
               Pa  : P.Path := Base;
            begin
               if Find (S, Key) = 0 then
                  P.Push_Field (Pa, To_String (Key));
                  Add_Diag (Err.Structural_Error, Err.Object_Unknown_Field, Pa,
                            "member is not declared by the schema");
                  Ok := False;
               end if;
            end;
         end loop;
      end if;
   end Validate;

end Representation.Schemas.Diagnostics;
