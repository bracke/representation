package body Representation.Results is

   --  Copy S into Target (1 .. Length), truncating deterministically.
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

   function Success return Outcome is
      O : Outcome;
   begin
      return O;  --  defaults: category Ok, empty id and message
   end Success;

   function Failure
     (Category : Representation.Errors.Error_Category;
      Error_Id : String;
      Message  : String := "") return Outcome
   is
      O : Outcome;
   begin
      O.Category := Category;
      Store (Error_Id, O.Id, O.Id_Length);
      Store (Message, O.Msg, O.Msg_Length);
      return O;
   end Failure;

   function Is_Ok (O : Outcome) return Boolean is
     (O.Category = Representation.Errors.Ok);

   function Category
     (O : Outcome) return Representation.Errors.Error_Category is (O.Category);

   function Error_Identifier (O : Outcome) return String is
     (O.Id (1 .. O.Id_Length));

   function Message (O : Outcome) return String is
     (O.Msg (1 .. O.Msg_Length));

end Representation.Results;
