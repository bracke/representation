package body Representation.Diagnostics is

   procedure Store
     (S      : String;
      Target : out String;
      Length : out Natural)
   is
      N : constant Natural :=
        (if S'Length > Target'Length then Target'Length else S'Length);
   begin
      Target := [others => ' '];
      Target (Target'First .. Target'First + N - 1) :=
        S (S'First .. S'First + N - 1);
      Length := N;
   end Store;

   function Make
     (Level    : Severity;
      Category : Representation.Errors.Error_Category;
      Error_Id : String;
      Path     : Representation.Paths.Path;
      Message  : String        := "";
      Offset   : Byte_Offset   := 0;
      Line     : Line_Number   := 0;
      Column   : Column_Number := 0) return Diagnostic
   is
      D : Diagnostic;
   begin
      D.Level := Level;
      D.Category := Category;
      Store (Error_Id, D.Id, D.Id_Length);
      Store (Message, D.Msg, D.Msg_Length);
      Store (Representation.Paths.Render (Path), D.Pa, D.Pa_Length);
      D.Offset := Offset;
      D.Line := Line;
      D.Column := Column;
      return D;
   end Make;

   function Level (D : Diagnostic) return Severity is (D.Level);

   function Category
     (D : Diagnostic) return Representation.Errors.Error_Category is
     (D.Category);

   function Error_Identifier (D : Diagnostic) return String is
     (D.Id (1 .. D.Id_Length));

   function Path_Render (D : Diagnostic) return String is
     (D.Pa (1 .. D.Pa_Length));

   function Message (D : Diagnostic) return String is
     (D.Msg (1 .. D.Msg_Length));

   function Offset (D : Diagnostic) return Byte_Offset is (D.Offset);
   function Line (D : Diagnostic) return Line_Number is (D.Line);
   function Column (D : Diagnostic) return Column_Number is (D.Column);

   procedure Clear (Set : out Diagnostic_Set) is
   begin
      Set.Count := 0;
      Set.Truncated := False;
   end Clear;

   procedure Add
     (Set      : in out Diagnostic_Set;
      Item     : Diagnostic;
      Capacity : Field_Count := Field_Count (Max_Entries))
   is
      Effective : constant Natural :=
        Natural'Min (Max_Entries, Natural (Capacity));
   begin
      if Set.Count >= Effective then
         Set.Truncated := True;
         return;
      end if;
      Set.Count := Set.Count + 1;
      Set.Items (Set.Count) := Item;
   end Add;

   function Count (Set : Diagnostic_Set) return Field_Count is
     (Field_Count (Set.Count));

   function Truncated (Set : Diagnostic_Set) return Boolean is (Set.Truncated);

   function Element
     (Set : Diagnostic_Set; Index : Positive) return Diagnostic is
     (Set.Items (Index));

end Representation.Diagnostics;
