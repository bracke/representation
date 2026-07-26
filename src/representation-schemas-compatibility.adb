with Representation.Identifiers;
with Representation.Fields;

package body Representation.Schemas.Compatibility is

   package FLD renames Representation.Fields;
   package Ids renames Representation.Identifiers;
   use type FLD.Presence_Policy;
   use type Representation.Objects.Unknown_Policy;

   function Canonical_Bytes (F : FLD.Field_Descriptor) return Byte_Array is
      S : constant String := Ids.Image (FLD.Canonical (F));
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Canonical_Bytes;

   --  Does a reader expecting Reader_Kind accept a writer producing Writer_Kind?
   function Kind_Accepts (Reader_Kind, Writer_Kind : Type_Kind) return Boolean is
   begin
      if Reader_Kind = Kind_Any or else Reader_Kind = Writer_Kind then
         return True;
      end if;
      --  An integer is a number; enum/reference values are strings on the wire.
      case Reader_Kind is
         when Kind_Number =>
            return Writer_Kind = Kind_Integer;
         when Kind_String =>
            return Writer_Kind in Kind_Enum | Kind_Reference;
         when others =>
            return False;
      end case;
   end Kind_Accepts;

   function Check_Read (Reader : Schema; Writer : Schema) return Result is
   begin
      --  Every field the reader requires must be guaranteed by the writer, and
      --  shared fields must have compatible declared types.
      for I in 1 .. Field_Count (Reader) loop
         declare
            RF   : constant FLD.Field_Descriptor := Field (Reader, I);
            Wdx  : constant Natural := Find (Writer, Canonical_Bytes (RF));
         begin
            if FLD.Presence (RF) = FLD.Required then
               if Wdx = 0
                 or else FLD.Presence (Field (Writer, Wdx)) /= FLD.Required
               then
                  return (Reason => Missing_Required, Field_Index => I);
               end if;
            end if;
            if Wdx /= 0
              and then not Kind_Accepts
                             (Field_Type (Reader, I), Field_Type (Writer, Wdx))
            then
               return (Reason => Type_Mismatch, Field_Index => I);
            end if;
         end;
      end loop;

      --  If the reader rejects unknowns, the writer must not emit a field the
      --  reader does not declare.
      if Unknown_Policy (Reader) = Representation.Objects.Reject then
         for J in 1 .. Field_Count (Writer) loop
            if Find (Reader, Canonical_Bytes (Field (Writer, J))) = 0 then
               return (Reason => Unknown_Rejected, Field_Index => J);
            end if;
         end loop;
      end if;

      return (Reason => Compatible, Field_Index => 0);
   end Check_Read;

end Representation.Schemas.Compatibility;
