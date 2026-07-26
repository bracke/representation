with Representation.JSON.Parser;
with Representation.Json_Escapes;
with Representation.Decimals;

package body Representation.JSON.Documents is

   package DM renames Representation.Documents;
   package Err renames Representation.Errors;

   function To_String (V : Byte_Array) return String is
      R : String (1 .. V'Length);
   begin
      for I in V'Range loop
         R (I - V'First + 1) := Character'Val (Natural (V (I)));
      end loop;
      return R;
   end To_String;

   function Starts (Id, Prefix : String) return Boolean is
     (Id'Length >= Prefix'Length
      and then Id (Id'First .. Id'First + Prefix'Length - 1) = Prefix);

   --  Map a stable machine error id to its top-level category.
   function Classify (Id : String) return Err.Error_Category is
   begin
      if Starts (Id, "representation.limit.") then
         return Err.Capacity_Failure;
      elsif Starts (Id, "representation.object.") then
         return Err.Structural_Error;
      elsif Starts (Id, "representation.io.") then
         return Err.IO_Failure;
      elsif Starts (Id, "representation.json.") then
         return Err.Syntax_Error;
      else
         return Err.Internal_Error;
      end if;
   end Classify;

   ---------------------------------------------------------------------------
   --  Decode
   ---------------------------------------------------------------------------

   procedure Decode
     (Doc            : in out Representation.Documents.Document;
      Source         : not null access Representation.Inputs.Source'Class;
      Result         : out Decode_Result;
      Read_Capacity  : Positive := 4096;
      Value_Capacity : Positive := 65_536;
      Limits         : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits;
      Reject_Duplicate_Keys : Boolean := True)
   is
      package PJ renames Representation.JSON.Parser;
      package ESC renames Representation.Json_Escapes;
      use type PJ.Event_Kind;
      use type DM.Node_Ref;
      use type DM.Node_Kind;
      use type ESC.Escape_Outcome;

      Depth_Cap : constant Positive :=
        (if Natural (Limits.Max_Depth) < 1 then 1 else Natural (Limits.Max_Depth));

      P  : PJ.Parser (Source, Read_Capacity, Value_Capacity, Depth_Cap, 0, 0);
      Ev : PJ.Event;

      Stack       : array (1 .. Depth_Cap) of DM.Node_Ref :=
                      [others => DM.No_Node];
      Top         : Natural := 0;
      Pending_Key : Byte_Array (1 .. Value_Capacity);
      Plen        : Natural := 0;
      Has_Pending : Boolean := False;
      Str_Buf     : Byte_Array (1 .. Value_Capacity);

      pragma Unreferenced (Has_Pending);

      procedure Set_Fail (Id : String; Cat : Err.Error_Category) is
         N : constant Natural :=
           (if Id'Length > Max_Error_Id then Max_Error_Id else Id'Length);
      begin
         Result.Ok        := False;
         Result.Root      := DM.No_Node;
         Result.Category  := Cat;
         Result.Offset    := Ev.Offset;
         Result.Line      := Ev.Line;
         Result.Column    := Ev.Column;
         Result.Error_Buf := [others => ' '];
         Result.Error_Buf (1 .. N) := Id (Id'First .. Id'First + N - 1);
         Result.Error_Len := N;
      end Set_Fail;

      --  Attach a freshly created node to its parent (or set it as the root).
      --  Returns False (and records failure) on arena overflow.
      function Attach (Node : DM.Node_Ref) return Boolean is
      begin
         if Node = DM.No_Node then
            Set_Fail (Err.Limit_Max_Bytes, Err.Capacity_Failure);
            return False;
         end if;
         if Top = 0 then
            DM.Set_Root (Doc, Node);
         elsif DM.Kind (Doc, Stack (Top)) = DM.Array_Node then
            DM.Append (Doc, Stack (Top), Node);
         else
            DM.Insert (Doc, Stack (Top), Pending_Key (1 .. Plen), Node);
            Has_Pending := False;
         end if;
         if DM.Overflowed (Doc) then
            Set_Fail (Err.Limit_Max_Bytes, Err.Capacity_Failure);
            return False;
         end if;
         return True;
      end Attach;

      function Decode_Str
        (Into : in out Byte_Array; Length : out Natural) return Boolean
      is
         Oc : ESC.Escape_Outcome;
      begin
         ESC.Decode (PJ.Value (P), Into, Length, Oc);
         if Oc = ESC.Escape_Ok then
            return True;
         end if;
         if Oc = ESC.Escape_Overflow then
            Set_Fail (Err.Limit_Max_Bytes, Err.Capacity_Failure);
         else
            Set_Fail (Err.Json_Invalid_Escape, Err.Syntax_Error);
         end if;
         return False;
      end Decode_Str;

   begin
      DM.Clear (Doc);
      PJ.Start (P, Limits, Reject_Duplicate_Keys => False);

      loop
         PJ.Next (P, Ev);
         case Ev.Kind is
            when PJ.Error =>
               declare
                  Id : constant String := PJ.Error_Id (P);
               begin
                  Set_Fail (Id, Classify (Id));
               end;
               return;

            when PJ.End_Of_Input =>
               Result.Ok       := True;
               Result.Category := Err.Ok;
               Result.Root     := DM.Root (Doc);
               return;

            when PJ.Start_Object =>
               declare
                  Node : constant DM.Node_Ref := DM.Add_Object (Doc);
               begin
                  if not Attach (Node) then
                     return;
                  end if;
                  Top := Top + 1;
                  Stack (Top) := Node;
               end;

            when PJ.Start_Array =>
               declare
                  Node : constant DM.Node_Ref := DM.Add_Array (Doc);
               begin
                  if not Attach (Node) then
                     return;
                  end if;
                  Top := Top + 1;
                  Stack (Top) := Node;
               end;

            when PJ.End_Object | PJ.End_Array =>
               Top := Top - 1;

            when PJ.Key =>
               if not Decode_Str (Pending_Key, Plen) then
                  return;
               end if;
               Has_Pending := True;
               if Reject_Duplicate_Keys and then Top > 0
                 and then DM.Find (Doc, Stack (Top), Pending_Key (1 .. Plen))
                          /= DM.No_Node
               then
                  Set_Fail (Err.Object_Duplicate_Field, Err.Structural_Error);
                  return;
               end if;

            when PJ.String_Value =>
               declare
                  Len : Natural;
               begin
                  if not Decode_Str (Str_Buf, Len) then
                     return;
                  end if;
                  if not Attach (DM.Add_String (Doc, Str_Buf (1 .. Len))) then
                     return;
                  end if;
               end;

            when PJ.Number_Value =>
               if not Attach (DM.Add_Number (Doc, PJ.Value (P))) then
                  return;
               end if;

            when PJ.Boolean_Value =>
               if not Attach (DM.Add_Bool (Doc, Ev.Bool)) then
                  return;
               end if;

            when PJ.Null_Value =>
               if not Attach (DM.Add_Null (Doc)) then
                  return;
               end if;
         end case;
      end loop;
   end Decode;

   ---------------------------------------------------------------------------
   --  Encode
   ---------------------------------------------------------------------------

   type Index_Vector is array (Positive range <>) of Positive;

   function Hex_Digit (N : Natural) return Character is
     (if N < 10 then Character'Val (Character'Pos ('0') + N)
      else Character'Val (Character'Pos ('a') + N - 10));

   function Zeros (N : Natural) return String is
     (if N = 0 then "" else [1 .. N => '0']);

   --  The canonical JSON spelling of an exact decimal: a plain decimal number
   --  (never scientific), with no leading/trailing zeros beyond what the value
   --  requires and no superfluous sign or point. Integers stay integers, so a
   --  decoded integer survives a canonical round-trip. Deterministic and
   --  idempotent: re-parsing renormalizes to the same value (trailing zeros are
   --  stripped), so re-encoding is a fixed point (REP-INV-001/008).
   function Canonical_Number
     (D : Representation.Decimals.Decimal) return String
   is
      use Representation.Decimals;
      Sig  : constant String  := Significand (D);   --  "0" for zero
      E    : constant Integer := Integer (Exponent (D));
      L    : constant Natural := Sig'Length;
      Sign : constant String  := (if Is_Negative (D) then "-" else "");
   begin
      if Is_Zero (D) then
         return "0";
      elsif E >= 0 then
         --  value = Sig * 10^E : an integer.
         return Sign & Sig & Zeros (E);
      else
         declare
            P : constant Natural := -E;   --  fractional digit count
         begin
            if P < L then
               return Sign
                 & Sig (Sig'First .. Sig'First + (L - P) - 1)
                 & "." & Sig (Sig'First + (L - P) .. Sig'Last);
            else
               return Sign & "0." & Zeros (P - L) & Sig;
            end if;
         end;
      end if;
   end Canonical_Number;

   procedure Encode
     (Doc    : Representation.Documents.Document;
      Root   : Representation.Documents.Node_Ref;
      Sink   : in out Representation.Outputs.Sink'Class;
      Style  : Encoding := Compact;
      Result : out Encode_Result)
   is
      package Sinks renames Representation.Outputs;
      use type Sinks.Write_Status;
      use type DM.Node_Kind;

      Is_Pretty : constant Boolean := Style = Pretty;
      Sort_Keys : constant Boolean := Style = Canonical;
      Norm_Nums : constant Boolean := Style = Canonical;
      Failed    : Boolean := False;

      Quote  : constant Byte := Byte (Character'Pos ('"'));
      Bslash : constant Byte := Byte (Character'Pos ('\'));

      procedure Put (Data : Byte_Array) is
         St : Sinks.Write_Status;
      begin
         if Failed or else Data'Length = 0 then
            return;
         end if;
         Sink.Write (Data, St);
         if St /= Sinks.Write_Ok then
            Failed := True;
         end if;
      end Put;

      procedure Put_Str (S : String) is
         Data : Byte_Array (1 .. S'Length);
      begin
         for I in S'Range loop
            Data (I - S'First + 1) := Byte (Character'Pos (S (I)));
         end loop;
         Put (Data);
      end Put_Str;

      procedure Newline_Indent (Level : Natural) is
      begin
         if not Is_Pretty then
            return;
         end if;
         Put ([16#0A#]);
         for I in 1 .. Level loop
            Put ([16#20#, 16#20#]);
         end loop;
      end Newline_Indent;

      procedure Put_Quoted (Text : Byte_Array) is
         Run_First : Natural := Text'First;

         procedure Flush (Upto : Integer) is
         begin
            if Upto >= Run_First then
               Put (Text (Run_First .. Upto));
            end if;
         end Flush;
      begin
         Put ([Quote]);
         for I in Text'Range loop
            declare
               B : constant Byte := Text (I);
            begin
               if B = Quote then
                  Flush (I - 1);
                  Put ([Bslash, Quote]);
                  Run_First := I + 1;
               elsif B = Bslash then
                  Flush (I - 1);
                  Put ([Bslash, Bslash]);
                  Run_First := I + 1;
               elsif B = 16#08# then
                  Flush (I - 1);
                  Put_Str ("\b");
                  Run_First := I + 1;
               elsif B = 16#09# then
                  Flush (I - 1);
                  Put_Str ("\t");
                  Run_First := I + 1;
               elsif B = 16#0A# then
                  Flush (I - 1);
                  Put_Str ("\n");
                  Run_First := I + 1;
               elsif B = 16#0C# then
                  Flush (I - 1);
                  Put_Str ("\f");
                  Run_First := I + 1;
               elsif B = 16#0D# then
                  Flush (I - 1);
                  Put_Str ("\r");
                  Run_First := I + 1;
               elsif B < 16#20# then
                  Flush (I - 1);
                  Put_Str ("\u00");
                  Put_Str ([Hex_Digit (Natural (B) / 16),
                            Hex_Digit (Natural (B) mod 16)]);
                  Run_First := I + 1;
               end if;
            end;
         end loop;
         Flush (Text'Last);
         Put ([Quote]);
      end Put_Quoted;

      procedure Put_Number (N : DM.Node_Ref) is
         T : constant Byte_Array := DM.Text (Doc, N);
      begin
         if Norm_Nums then
            declare
               use Representation.Decimals;
               D  : Decimal;
               Oc : Parse_Outcome;
            begin
               Parse (To_String (T), D, Oc);
               if Oc = Decimal_Ok then
                  Put_Str (Canonical_Number (D));
                  return;
               end if;
            end;
         end if;
         Put (T);
      end Put_Number;

      function Key_Less (A, B : Byte_Array) return Boolean is
         N : constant Natural := Natural'Min (A'Length, B'Length);
      begin
         for I in 0 .. N - 1 loop
            if A (A'First + I) /= B (B'First + I) then
               return A (A'First + I) < B (B'First + I);
            end if;
         end loop;
         return A'Length < B'Length;
      end Key_Less;

      procedure Sort_Members (N : DM.Node_Ref; Order : in out Index_Vector) is
      begin
         for I in Order'First + 1 .. Order'Last loop
            declare
               V : constant Positive := Order (I);
               J : Natural := I - 1;
            begin
               while J >= Order'First
                 and then Key_Less (DM.Member_Key (Doc, N, V),
                                    DM.Member_Key (Doc, N, Order (J)))
               loop
                  Order (J + 1) := Order (J);
                  J := J - 1;
               end loop;
               Order (J + 1) := V;
            end;
         end loop;
      end Sort_Members;

      procedure Enc (N : DM.Node_Ref; Level : Natural) is
      begin
         if Failed then
            return;
         end if;
         case DM.Kind (Doc, N) is
            when DM.Null_Node =>
               Put_Str ("null");
            when DM.Bool_Node =>
               Put_Str ((if DM.Bool_Value (Doc, N) then "true" else "false"));
            when DM.Number_Node =>
               Put_Number (N);
            when DM.String_Node =>
               Put_Quoted (DM.Text (Doc, N));
            when DM.Array_Node =>
               declare
                  Len : constant Natural := DM.Length (Doc, N);
               begin
                  if Len = 0 then
                     Put_Str ("[]");
                     return;
                  end if;
                  Put_Str ("[");
                  for I in 1 .. Len loop
                     if I > 1 then
                        Put_Str (",");
                     end if;
                     Newline_Indent (Level + 1);
                     Enc (DM.Element (Doc, N, I), Level + 1);
                  end loop;
                  Newline_Indent (Level);
                  Put_Str ("]");
               end;
            when DM.Object_Node =>
               declare
                  Len   : constant Natural := DM.Length (Doc, N);
                  Order : Index_Vector (1 .. Len);
               begin
                  if Len = 0 then
                     Put_Str ("{}");
                     return;
                  end if;
                  for I in 1 .. Len loop
                     Order (I) := I;
                  end loop;
                  if Sort_Keys then
                     Sort_Members (N, Order);
                  end if;
                  Put_Str ("{");
                  for K in 1 .. Len loop
                     if K > 1 then
                        Put_Str (",");
                     end if;
                     Newline_Indent (Level + 1);
                     Put_Quoted (DM.Member_Key (Doc, N, Order (K)));
                     Put_Str ((if Is_Pretty then ": " else ":"));
                     Enc (DM.Member (Doc, N, Order (K)), Level + 1);
                  end loop;
                  Newline_Indent (Level);
                  Put_Str ("}");
               end;
         end case;
      end Enc;

   begin
      Result := (Ok => True, Category => Err.Ok);
      Enc (Root, 0);
      if Failed then
         Result := (Ok => False, Category => Err.IO_Failure);
      end if;
   end Encode;

end Representation.JSON.Documents;
