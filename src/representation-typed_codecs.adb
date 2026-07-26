package body Representation.Typed_Codecs is

   package DM renames Representation.Documents;
   package JD renames Representation.JSON.Documents;
   package Obj renames Representation.Objects;
   package Err renames Representation.Errors;
   use type DM.Node_Ref;

   procedure Set_Report
     (R : out Decode_Report; Cat : Err.Error_Category; Id : String;
      Offset : Byte_Offset; Line : Line_Number; Column : Column_Number)
   is
      N : constant Natural :=
        (if Id'Length > Max_Error_Id then Max_Error_Id else Id'Length);
   begin
      R.Ok        := False;
      R.Category  := Cat;
      R.Offset    := Offset;
      R.Line      := Line;
      R.Column    := Column;
      R.Error_Buf := [others => ' '];
      R.Error_Buf (1 .. N) := Id (Id'First .. Id'First + N - 1);
      R.Error_Len := N;
   end Set_Report;

   procedure Decode
     (Source   : not null access Representation.Inputs.Source'Class;
      Contract : Representation.Fields.Field_Set;
      Value    : out Value_Type;
      Report   : out Decode_Report;
      Policy   : Obj.Unknown_Policy := Obj.Reject;
      Node_Capacity  : Positive := 4096;
      Text_Capacity  : Positive := 65_536;
      Read_Capacity  : Positive := 4096;
      Value_Capacity : Positive := 65_536;
      Limits         : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits)
   is
      Doc : DM.Document (Node_Capacity, Text_Capacity);
      DR  : JD.Decode_Result;
      OS  : Obj.Object_Status;
      Ok  : Boolean;
   begin
      Report := (Ok => False, others => <>);

      JD.Decode (Doc, Source, DR, Read_Capacity, Value_Capacity, Limits);
      if not DR.Ok then
         Set_Report (Report, DR.Category, JD.Error_Id (DR),
                     DR.Offset, DR.Line, DR.Column);
         return;
      end if;

      Obj.Validate (Doc, DR.Root, Contract, Policy, OS);
      if not OS.Ok then
         Set_Report (Report, OS.Category, Obj.Error_Id (OS), 0, 1, 1);
         return;
      end if;

      Read (Doc, DR.Root, Value, Ok);
      if not Ok then
         Set_Report (Report, Err.Representation_Constraint, "", 0, 1, 1);
         return;
      end if;

      Report := (Ok => True, others => <>);
      Report.Category := Err.Ok;
   end Decode;

   procedure Encode
     (Value  : Value_Type;
      Sink   : in out Representation.Outputs.Sink'Class;
      Report : out Encode_Report;
      Style  : JD.Encoding := JD.Compact;
      Node_Capacity : Positive := 4096;
      Text_Capacity : Positive := 65_536)
   is
      Doc  : DM.Document (Node_Capacity, Text_Capacity);
      Root : DM.Node_Ref;
      ER   : JD.Encode_Result;
   begin
      Write (Doc, Value, Root);
      if Root = DM.No_Node or else DM.Overflowed (Doc) then
         Report := (Ok => False, Category => Err.Capacity_Failure);
         return;
      end if;

      JD.Encode (Doc, Root, Sink, Style, ER);
      if not ER.Ok then
         Report := (Ok => False, Category => ER.Category);
         return;
      end if;
      Report := (Ok => True, Category => Err.Ok);
   end Encode;

end Representation.Typed_Codecs;
