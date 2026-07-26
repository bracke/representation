package body Representation.References is

   package DM renames Representation.Documents;
   use type DM.Node_Kind;

   procedure Make
     (Target : Byte_Array; Ref : out Reference; Status : out Reference_Status) is
   begin
      Ref := Null_Reference;
      if Target'Length = 0 then
         Status := Reference_Empty;
         return;
      elsif Target'Length > Max_Reference_Length then
         Status := Reference_Too_Long;
         return;
      end if;
      Ref.Len := Target'Length;
      Ref.Data (1 .. Target'Length) := Target;
      Status := Reference_Ok;
   end Make;

   function Is_Null (Ref : Reference) return Boolean is (Ref.Len = 0);

   function Target (Ref : Reference) return Byte_Array is (Ref.Data (1 .. Ref.Len));

   procedure Decode
     (Doc    : DM.Document;
      N      : DM.Node_Ref;
      Ref    : out Reference;
      Status : out Reference_Status) is
   begin
      if DM.Kind (Doc, N) /= DM.String_Node then
         Ref := Null_Reference;
         Status := Reference_Wrong_Kind;
         return;
      end if;
      Make (DM.Text (Doc, N), Ref, Status);
   end Decode;

   function Encode
     (Doc : in out DM.Document; Ref : Reference)
      return DM.Node_Ref is
     (if Ref.Len = 0 then DM.No_Node
      else DM.Add_String (Doc, Ref.Data (1 .. Ref.Len)));

end Representation.References;
