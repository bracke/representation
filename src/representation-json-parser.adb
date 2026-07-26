with Representation.Errors;

package body Representation.JSON.Parser is

   package Lx renames Representation.JSON.Lexer;
   use type Lx.Token_Kind;

   function Is_Value_Start (K : Lx.Token_Kind) return Boolean is
     (K in Lx.Tok_Begin_Object | Lx.Tok_Begin_Array | Lx.Tok_String
         | Lx.Tok_Number | Lx.Tok_True | Lx.Tok_False | Lx.Tok_Null);

   procedure Start
     (P      : in out Parser;
      Limits : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits;
      Reject_Duplicate_Keys : Boolean := True) is
   begin
      Lx.Start (P.Lex, Limits);
      P.Limits   := Limits;
      P.Dedup    := Reject_Duplicate_Keys;
      P.State    := Expect_Doc_Value;
      P.Top      := 0;
      P.Values   := 0;
      P.Work     := Limits.Work_Budget;
      P.Key_Top  := 0;
      P.Pool_Top := 0;
      P.Err_Len  := 0;
      P.Term     := End_Of_Input;
   end Start;

   procedure Next (P : in out Parser; Ev : out Event) is
      Tok : Lx.Token;

      function After_Value_State return Parse_State is
        (if P.Top = 0 then Doc_Complete else Expect_Comma_Or_End);

      procedure Emit (Kind : Event_Kind; B : Boolean := False) is
      begin
         Ev := (Kind   => Kind,
                Offset => Tok.Offset,
                Line   => Tok.Line,
                Column => Tok.Column,
                Depth  => Depth_Count (P.Top),
                Bool   => B);
      end Emit;

      procedure Set_Err (Id : String) is
         N : constant Natural := (if Id'Length > 64 then 64 else Id'Length);
      begin
         P.Err := [others => ' '];
         P.Err (1 .. N) := Id (Id'First .. Id'First + N - 1);
         P.Err_Len := N;
      end Set_Err;

      procedure Fail (Id : String) is
      begin
         Set_Err (Id);
         P.State := Parser_Failed;
         P.Term  := Error;
         Emit (Error);
      end Fail;

      --  A grammar violation: distinguish a premature end of input from a
      --  merely misplaced token so diagnostics stay honest.
      procedure Grammar_Fail is
      begin
         if Tok.Kind = Lx.Tok_End_Of_Input then
            Fail (Representation.Errors.Json_Unexpected_End);
         else
            Fail (Representation.Errors.Json_Invalid_Token);
         end if;
      end Grammar_Fail;

      --  Read the next token, charging the work budget and propagating any
      --  lexer error. Returns False (with Ev set to Error) on failure.
      function Read return Boolean is
      begin
         if P.Work = 0 then
            Fail (Representation.Errors.Limit_Work_Budget);
            return False;
         end if;
         P.Work := P.Work - 1;
         Lx.Next (P.Lex, Tok);
         if Tok.Kind = Lx.Tok_Error then
            Fail (Lx.Error_Id (P.Lex));
            return False;
         end if;
         return True;
      end Read;

      function Count_Value return Boolean is
      begin
         if P.Values >= P.Limits.Max_Total_Values then
            Fail (Representation.Errors.Limit_Work_Budget);
            return False;
         end if;
         P.Values := P.Values + 1;
         return True;
      end Count_Value;

      function Count_Element return Boolean is
      begin
         P.Stack (P.Top).Count := P.Stack (P.Top).Count + 1;
         if Element_Count (P.Stack (P.Top).Count) > P.Limits.Max_Array_Elements
         then
            Fail (Representation.Errors.Limit_Max_Elements);
            return False;
         end if;
         return True;
      end Count_Element;

      function Count_Member return Boolean is
      begin
         P.Stack (P.Top).Count := P.Stack (P.Top).Count + 1;
         if Field_Count (P.Stack (P.Top).Count) > P.Limits.Max_Object_Members
         then
            Fail (Representation.Errors.Limit_Max_Members);
            return False;
         end if;
         return True;
      end Count_Member;

      function Push (K : Container_Kind) return Boolean is
      begin
         if P.Top >= P.Depth_Capacity
           or else Depth_Count (P.Top) >= P.Limits.Max_Depth
         then
            Fail (Representation.Errors.Limit_Max_Depth);
            return False;
         end if;
         P.Top := P.Top + 1;
         P.Stack (P.Top) := (Kind      => K,
                             Count     => 0,
                             Key_Base  => P.Key_Top,
                             Pool_Base => P.Pool_Top);
         return True;
      end Push;

      procedure Pop is
      begin
         if P.Stack (P.Top).Kind = In_Object then
            P.Key_Top  := P.Stack (P.Top).Key_Base;
            P.Pool_Top := P.Stack (P.Top).Pool_Base;
         end if;
         P.Top := P.Top - 1;
      end Pop;

      --  Check the just-read string key against the current object's seen keys
      --  and record it. Returns False (Ev = Error) on duplicate or store
      --  exhaustion; a no-op when duplicate detection is disabled.
      function Accept_Key return Boolean is
         V : constant Byte_Array := Lx.Value (P.Lex);
      begin
         if not (P.Dedup and then P.Key_Pool_Bytes > 0 and then P.Key_Slots > 0)
         then
            return True;
         end if;

         for I in P.Stack (P.Top).Key_Base + 1 .. P.Key_Top loop
            declare
               R : Key_Ref renames P.Keys (I);
            begin
               if R.Len = V'Length
                 and then P.Pool (R.Start .. R.Start + R.Len - 1) = V
               then
                  Fail (Representation.Errors.Object_Duplicate_Field);
                  return False;
               end if;
            end;
         end loop;

         if P.Key_Top >= P.Key_Slots then
            Fail (Representation.Errors.Limit_Max_Members);
            return False;
         end if;
         if P.Pool_Top + V'Length > P.Key_Pool_Bytes then
            Fail (Representation.Errors.Limit_Max_Bytes);
            return False;
         end if;

         P.Keys (P.Key_Top + 1) := (Start => P.Pool_Top + 1, Len => V'Length);
         if V'Length > 0 then
            P.Pool (P.Pool_Top + 1 .. P.Pool_Top + V'Length) := V;
         end if;
         P.Key_Top  := P.Key_Top + 1;
         P.Pool_Top := P.Pool_Top + V'Length;
         return True;
      end Accept_Key;

      --  Dispatch a token that must begin a value. Emits the value event (or a
      --  Start_Object/Start_Array that pushes a container) and sets the next
      --  state. Returns False (Ev = Error) if the token cannot start a value.
      function Dispatch_Value return Boolean is
      begin
         if Is_Value_Start (Tok.Kind) and then not Count_Value then
            return False;
         end if;
         case Tok.Kind is
            when Lx.Tok_Begin_Object =>
               if not Push (In_Object) then
                  return False;
               end if;
               P.State := Expect_Object_Key;
               Emit (Start_Object);
            when Lx.Tok_Begin_Array =>
               if not Push (In_Array) then
                  return False;
               end if;
               P.State := Expect_Array_Item;
               Emit (Start_Array);
            when Lx.Tok_String =>
               P.State := After_Value_State;
               Emit (String_Value);
            when Lx.Tok_Number =>
               P.State := After_Value_State;
               Emit (Number_Value);
            when Lx.Tok_True =>
               P.State := After_Value_State;
               Emit (Boolean_Value, True);
            when Lx.Tok_False =>
               P.State := After_Value_State;
               Emit (Boolean_Value, False);
            when Lx.Tok_Null =>
               P.State := After_Value_State;
               Emit (Null_Value);
            when Lx.Tok_End_Of_Input =>
               Fail (Representation.Errors.Json_Unexpected_End);
               return False;
            when others =>
               Fail (Representation.Errors.Json_Invalid_Token);
               return False;
         end case;
         return True;
      end Dispatch_Value;

   begin
      loop
         case P.State is
            when Parser_Failed =>
               Ev := (Kind   => Error,
                      Offset => 0, Line => 1, Column => 1,
                      Depth  => Depth_Count (P.Top), Bool => False);
               return;

            when Doc_Ended =>
               Ev := (Kind   => End_Of_Input,
                      Offset => 0, Line => 1, Column => 1,
                      Depth  => 0, Bool => False);
               return;

            when Expect_Doc_Value | Expect_Member_Value =>
               if not Read then
                  return;
               end if;
               if not Dispatch_Value then
                  return;
               end if;
               return;

            when Expect_Element =>
               if not Read then
                  return;
               end if;
               if Is_Value_Start (Tok.Kind) and then not Count_Element then
                  return;
               end if;
               if not Dispatch_Value then
                  return;
               end if;
               return;

            when Expect_Array_Item =>
               if not Read then
                  return;
               end if;
               if Tok.Kind = Lx.Tok_End_Array then
                  Pop;
                  P.State := After_Value_State;
                  Emit (End_Array);
                  return;
               end if;
               if Is_Value_Start (Tok.Kind) and then not Count_Element then
                  return;
               end if;
               if not Dispatch_Value then
                  return;
               end if;
               return;

            when Expect_Object_Key | Expect_Object_Key2 =>
               if not Read then
                  return;
               end if;
               if P.State = Expect_Object_Key
                 and then Tok.Kind = Lx.Tok_End_Object
               then
                  Pop;
                  P.State := After_Value_State;
                  Emit (End_Object);
                  return;
               elsif Tok.Kind = Lx.Tok_String then
                  if not Count_Member then
                     return;
                  end if;
                  if not Accept_Key then
                     return;
                  end if;
                  P.State := Expect_Colon;
                  Emit (Key);
                  return;
               else
                  Grammar_Fail;
                  return;
               end if;

            when Expect_Colon =>
               if not Read then
                  return;
               end if;
               if Tok.Kind = Lx.Tok_Name_Separator then
                  P.State := Expect_Member_Value;
                  --  Fall through to read the member value in this call.
               else
                  Grammar_Fail;
                  return;
               end if;

            when Expect_Comma_Or_End =>
               if not Read then
                  return;
               end if;
               if Tok.Kind = Lx.Tok_Value_Separator then
                  if P.Stack (P.Top).Kind = In_Object then
                     P.State := Expect_Object_Key2;
                  else
                     P.State := Expect_Element;
                  end if;
                  --  Fall through to read the next key/element in this call.
               elsif Tok.Kind = Lx.Tok_End_Object
                 and then P.Stack (P.Top).Kind = In_Object
               then
                  Pop;
                  P.State := After_Value_State;
                  Emit (End_Object);
                  return;
               elsif Tok.Kind = Lx.Tok_End_Array
                 and then P.Stack (P.Top).Kind = In_Array
               then
                  Pop;
                  P.State := After_Value_State;
                  Emit (End_Array);
                  return;
               else
                  Grammar_Fail;
                  return;
               end if;

            when Doc_Complete =>
               if not Read then
                  return;
               end if;
               if Tok.Kind = Lx.Tok_End_Of_Input then
                  P.State := Doc_Ended;
                  Emit (End_Of_Input);
                  return;
               else
                  Fail (Representation.Errors.Json_Trailing_Input);
                  return;
               end if;
         end case;
      end loop;
   end Next;

   function Value (P : Parser) return Byte_Array is
     (Representation.JSON.Lexer.Value (P.Lex));

   function Error_Id (P : Parser) return String is (P.Err (1 .. P.Err_Len));

end Representation.JSON.Parser;
