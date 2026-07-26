package body Representation.Arrays is

   package DM renames Representation.Documents;
   use type DM.Node_Kind;

   function Is_Array
     (Doc : DM.Document; N : DM.Node_Ref) return Boolean is
     (DM.Kind (Doc, N) = DM.Array_Node);

   function Length (Doc : DM.Document; N : DM.Node_Ref) return Natural is
     (if Is_Array (Doc, N) then DM.Length (Doc, N) else 0);

   function Element
     (Doc : DM.Document; N : DM.Node_Ref; Index : Positive)
      return DM.Node_Ref is
     (DM.Element (Doc, N, Index));

   function New_Array (Doc : in out DM.Document) return DM.Node_Ref is
     (DM.Add_Array (Doc));

   procedure Append
     (Doc : in out DM.Document; Arr : DM.Node_Ref; Elem : DM.Node_Ref) is
   begin
      DM.Append (Doc, Arr, Elem);
   end Append;

   package body Reader is

      procedure Read
        (Doc    : DM.Document;
         N      : DM.Node_Ref;
         Into   : out Vector;
         Count  : out Natural;
         Status : out Read_Status)
      is
         Len : Natural;
      begin
         Count := 0;
         if not Is_Array (Doc, N) then
            Status := Read_Wrong_Kind;
            return;
         end if;
         Len := DM.Length (Doc, N);
         if Len > Into'Length then
            Status := Read_Overflow;
            return;
         end if;
         for I in 1 .. Len loop
            declare
               V  : Element;
               Ok : Boolean;
            begin
               Read_Element (Doc, DM.Element (Doc, N, I), V, Ok);
               if not Ok then
                  Count := I - 1;
                  Status := Read_Element_Failed;
                  return;
               end if;
               Into (Into'First + I - 1) := V;
            end;
         end loop;
         Count := Len;
         Status := Read_Ok;
      end Read;

   end Reader;

end Representation.Arrays;
