with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Metadata;
with Representation.Links;
with Representation.Pagination;
with Representation.Envelopes;
with Representation.Codecs.Registries;

package body Envelopes_Tests is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package MD renames Representation.Metadata;
   package LK renames Representation.Links;
   package PG renames Representation.Pagination;
   package Env renames Representation.Envelopes;
   package Reg renames Representation.Codecs.Registries;
   use type DM.Node_Ref;
   use type DM.Node_Kind;

   function To_Bytes (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end To_Bytes;

   function To_Str (B : Byte_Array) return String is
      R : String (1 .. B'Length);
   begin
      for I in B'Range loop
         R (I - B'First + 1) := Character'Val (Natural (B (I)));
      end loop;
      return R;
   end To_Str;

   procedure Test_Envelope (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc     : DM.Document (64, 512);
      M       : MD.Meta (4, 64);
      L       : LK.Link_Set (4, 128);
      Added   : Boolean;
      Data    : DM.Node_Ref;
      Envelope : DM.Node_Ref;
   begin
      MD.Add (M, To_Bytes ("request-id"),
              DM.Add_String (Doc, To_Bytes ("r-1")), Added);
      LK.Add (L, To_Bytes ("self"), To_Bytes ("/x"), Added);

      Data := DM.Add_Object (Doc);
      DM.Insert (Doc, Data, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("7")));

      Envelope := Env.Build
        (Doc, Data,
         Meta  => MD.To_Object (M, Doc),
         Links => LK.To_Object (L, Doc),
         Page  => PG.To_Object (PG.Make (Limit => 10), Doc));

      Assert (Env.Data (Doc, Envelope) = Data, "data section is the payload");
      Assert (DM.Kind (Doc, Env.Meta (Doc, Envelope)) = DM.Object_Node,
              "meta section present");
      Assert (DM.Kind (Doc, Env.Links (Doc, Envelope)) = DM.Object_Node,
              "links section present");
      Assert (DM.Kind (Doc, Env.Page (Doc, Envelope)) = DM.Object_Node,
              "page section present");
      Assert (Env.Errors (Doc, Envelope) = DM.No_Node, "errors omitted");
      Assert (not Env.Has_Errors (Doc, Envelope), "no errors");
   end Test_Envelope;

   procedure Test_Envelope_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc   : DM.Document (32, 256);
      Errs  : DM.Node_Ref;
      One   : DM.Node_Ref;
      Envelope : DM.Node_Ref;
   begin
      Errs := DM.Add_Array (Doc);
      One  := DM.Add_Object (Doc);
      DM.Insert (Doc, One, To_Bytes ("code"),
                 DM.Add_String (Doc, To_Bytes ("bad")));
      DM.Append (Doc, Errs, One);

      Envelope := Env.Build (Doc, DM.No_Node, Errors => Errs);
      Assert (Env.Has_Errors (Doc, Envelope), "non-empty errors section");
      Assert (Env.Data (Doc, Envelope) = DM.No_Node, "no data section");
   end Test_Envelope_Errors;

   procedure Test_Registry (T : in out Fixture) is
      pragma Unreferenced (T);
      R     : Reg.Registry (4, 128);
      Added : Boolean;
   begin
      Reg.Start (R);
      Reg.Register (R, Ids.To_Codec_Id ("json"),
                    To_Bytes ("application/json"), Added);
      Assert (Added, "register json");
      Reg.Register (R, Ids.To_Codec_Id ("json"),
                    To_Bytes ("text/json"), Added);
      Assert (not Added, "duplicate id refused");
      Reg.Register (R, Ids.To_Codec_Id ("cbor"),
                    To_Bytes ("application/cbor"), Added);
      Assert (Added and then Reg.Count (R) = 2, "two codecs");

      Assert (Reg.Contains (R, Ids.To_Codec_Id ("json")), "contains json");
      Assert (To_Str (Reg.Media_Type (R, Ids.To_Codec_Id ("json")))
              = "application/json", "media type lookup");

      Reg.Finalize (R);
      Reg.Register (R, Ids.To_Codec_Id ("xml"),
                    To_Bytes ("application/xml"), Added);
      Assert (not Added and then Reg.Count (R) = 2,
              "registry immutable after finalize (REP-INV-020)");
   end Test_Registry;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Envelopes: build", Test_Envelope'Access));
      Suite.Add_Test
        (Caller.Create ("Envelopes: errors", Test_Envelope_Errors'Access));
      Suite.Add_Test (Caller.Create ("Codecs: registry", Test_Registry'Access));
   end Add_Tests;

end Envelopes_Tests;
