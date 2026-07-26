with Representation.Paths;
with Representation.Schemas.Diagnostics;

package body Representation.JSON.Typed is

   package DM renames Representation.Documents;
   package JD renames Representation.JSON.Documents;
   package D renames Representation.Diagnostics;
   package SD renames Representation.Schemas.Diagnostics;

   procedure Decode
     (Source         : not null access Representation.Inputs.Source'Class;
      Schema         : Representation.Schemas.Schema;
      Doc            : in out DM.Document;
      Root           : out DM.Node_Ref;
      Report         : in out D.Diagnostic_Set;
      Ok             : out Boolean;
      Read_Capacity  : Positive := 4096;
      Value_Capacity : Positive := 65_536;
      Limits         : Representation.Limits.Limits :=
        Representation.Limits.Default_Limits)
   is
      DR : JD.Decode_Result;
   begin
      Root := DM.No_Node;
      Ok   := False;

      JD.Decode (Doc, Source, DR, Read_Capacity, Value_Capacity, Limits);
      if not DR.Ok then
         --  A syntax/structure failure is one diagnostic located by position.
         D.Add
           (Report,
            D.Make (Level    => D.Error,
                    Category => DR.Category,
                    Error_Id => JD.Error_Id (DR),
                    Path     => Representation.Paths.Empty_Path,
                    Offset   => DR.Offset,
                    Line     => DR.Line,
                    Column   => DR.Column));
         return;
      end if;

      Root := DR.Root;
      SD.Validate (Doc, Root, Schema, Representation.Paths.Empty_Path,
                   Report, Ok);
   end Decode;

   procedure Encode
     (Doc   : DM.Document;
      Root  : DM.Node_Ref;
      Sink  : in out Representation.Outputs.Sink'Class;
      Style : Encoding := Representation.JSON.Documents.Compact;
      Ok    : out Boolean)
   is
      ER : JD.Encode_Result;
   begin
      JD.Encode (Doc, Root, Sink, Style, ER);
      Ok := ER.Ok;
   end Encode;

end Representation.JSON.Typed;
