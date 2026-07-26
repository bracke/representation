with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Errors;
with Representation.Fields;
with Representation.Objects;
with Representation.Arrays;
with Representation.Extensions;
with Representation.Values;

package body Objects_Tests is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Obj renames Representation.Objects;
   package Ext renames Representation.Extensions;

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

   --  A small contract: required "id", required "name" (alias "nick").
   function F_Id return FLD.Field_Descriptor is
     (FLD.Make (Ids.To_Field_Id ("id"), FLD.Required));
   function F_Name return FLD.Field_Descriptor is
     (FLD.With_Alias
        (FLD.Make (Ids.To_Field_Id ("name"), FLD.Required),
         Ids.To_Field_Id ("nick")));

   procedure Test_Fields (T : in out Fixture) is
      pragma Unreferenced (T);
      F : constant FLD.Field_Descriptor := F_Name;
      use type FLD.Presence_Policy;
   begin
      Assert (Ids.Image (FLD.Canonical (F)) = "name", "canonical name");
      Assert (FLD.Presence (F) = FLD.Required, "presence");
      Assert (FLD.Alias_Count (F) = 1, "one alias");
      Assert (FLD.Matches (F, To_Bytes ("name")), "matches canonical");
      Assert (FLD.Matches (F, To_Bytes ("nick")), "matches alias");
      Assert (not FLD.Matches (F, To_Bytes ("other")), "no false match");
   end Test_Fields;

   procedure Test_Lookup_Order_Independent (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (16, 128);
      O1   : DM.Node_Ref;
      O2   : DM.Node_Ref;
   begin
      --  Same content, members in opposite order.
      O1 := DM.Add_Object (Doc);
      DM.Insert (Doc, O1, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));
      DM.Insert (Doc, O1, To_Bytes ("name"), DM.Add_String (Doc, To_Bytes ("a")));

      O2 := DM.Add_Object (Doc);
      DM.Insert (Doc, O2, To_Bytes ("name"), DM.Add_String (Doc, To_Bytes ("a")));
      DM.Insert (Doc, O2, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));

      Assert (To_Str (DM.Text (Doc, Obj.Lookup (Doc, O1, F_Id))) = "1"
              and then To_Str (DM.Text (Doc, Obj.Lookup (Doc, O2, F_Id))) = "1",
              "id found regardless of order");
      Assert (To_Str (DM.Text (Doc, Obj.Lookup (Doc, O2, F_Name))) = "a",
              "name found regardless of order");
   end Test_Lookup_Order_Independent;

   procedure Test_Validate_Required (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc      : DM.Document (16, 128);
      Contract : constant Obj.Field_Set := [F_Id, F_Name];
      Good, Bad : DM.Node_Ref;
      St       : Obj.Object_Status;
   begin
      Good := DM.Add_Object (Doc);
      DM.Insert (Doc, Good, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));
      DM.Insert (Doc, Good, To_Bytes ("nick"),
                 DM.Add_String (Doc, To_Bytes ("a")));   --  name via alias
      Obj.Validate (Doc, Good, Contract, Obj.Reject, St);
      Assert (St.Ok, "required satisfied (name via alias)");

      Bad := DM.Add_Object (Doc);
      DM.Insert (Doc, Bad, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));
      Obj.Validate (Doc, Bad, Contract, Obj.Reject, St);
      Assert (not St.Ok
              and then Obj.Error_Id (St)
                       = Representation.Errors.Object_Missing_Field,
              "missing required name");
   end Test_Validate_Required;

   procedure Test_Validate_Unknown_Policy (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc      : DM.Document (16, 128);
      Contract : constant Obj.Field_Set := [F_Id, F_Name];
      O        : DM.Node_Ref;
      St       : Obj.Object_Status;
   begin
      O := DM.Add_Object (Doc);
      DM.Insert (Doc, O, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));
      DM.Insert (Doc, O, To_Bytes ("name"), DM.Add_String (Doc, To_Bytes ("a")));
      DM.Insert (Doc, O, To_Bytes ("extra"), DM.Add_Bool (Doc, True));

      Obj.Validate (Doc, O, Contract, Obj.Reject, St);
      Assert (not St.Ok
              and then Obj.Error_Id (St)
                       = Representation.Errors.Object_Unknown_Field,
              "unknown member rejected");

      Obj.Validate (Doc, O, Contract, Obj.Ignore, St);
      Assert (St.Ok, "unknown member ignored");

      Obj.Validate (Doc, O, Contract, Obj.Preserve, St);
      Assert (St.Ok, "unknown member preserved (validation passes)");
   end Test_Validate_Unknown_Policy;

   procedure Test_Validate_Duplicate (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc      : DM.Document (16, 128);
      Contract : constant Obj.Field_Set := [F_Id, F_Name];
      O        : DM.Node_Ref;
      St       : Obj.Object_Status;
   begin
      O := DM.Add_Object (Doc);
      DM.Insert (Doc, O, To_Bytes ("id"), DM.Add_Number (Doc, To_Bytes ("1")));
      --  Same field supplied under its canonical name and its alias.
      DM.Insert (Doc, O, To_Bytes ("name"), DM.Add_String (Doc, To_Bytes ("a")));
      DM.Insert (Doc, O, To_Bytes ("nick"), DM.Add_String (Doc, To_Bytes ("b")));
      Obj.Validate (Doc, O, Contract, Obj.Reject, St);
      Assert (not St.Ok
              and then Obj.Error_Id (St)
                       = Representation.Errors.Object_Duplicate_Field,
              "canonical + alias is a duplicate");
   end Test_Validate_Duplicate;

   procedure Test_Encode_Canonical_Names (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : DM.Document (16, 128);
      O   : DM.Node_Ref;
   begin
      O := Obj.New_Object (Doc);
      --  Even though F_Name has an alias, the emitted key is the canonical name.
      Obj.Put_Field (Doc, O, F_Name, DM.Add_String (Doc, To_Bytes ("a")));
      Assert (DM.Length (Doc, O) = 1, "one member");
      Assert (To_Str (DM.Member_Key (Doc, O, 1)) = "name",
              "canonical name emitted, never the alias");
   end Test_Encode_Canonical_Names;

   type Int_Vector is array (Positive range <>) of Integer;

   procedure Read_Int
     (Doc : DM.Document; N : DM.Node_Ref; Value : out Integer; Ok : out Boolean)
   is
      LL : Long_Long_Integer;
      St : Representation.Values.Value_Status;
      use type Representation.Values.Value_Status;
   begin
      Representation.Values.Get_Integer (Doc, N, LL, St);
      Ok := St = Representation.Values.Value_Ok;
      Value := (if Ok then Integer (LL) else 0);
   end Read_Int;

   package Int_Reader is new Representation.Arrays.Reader
     (Element => Integer, Vector => Int_Vector, Read_Element => Read_Int);

   procedure Test_Arrays_Reader (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (16, 128);
      Arr  : DM.Node_Ref;
      Out3 : Int_Vector (1 .. 3);
      Out2 : Int_Vector (1 .. 2);
      Cnt  : Natural;
      St   : Int_Reader.Read_Status;
      use type Int_Reader.Read_Status;
   begin
      Arr := DM.Add_Array (Doc);
      DM.Append (Doc, Arr, DM.Add_Number (Doc, To_Bytes ("10")));
      DM.Append (Doc, Arr, DM.Add_Number (Doc, To_Bytes ("20")));
      DM.Append (Doc, Arr, DM.Add_Number (Doc, To_Bytes ("30")));

      Int_Reader.Read (Doc, Arr, Out3, Cnt, St);
      Assert (St = Int_Reader.Read_Ok and then Cnt = 3
              and then Out3 = [10, 20, 30], "reads array into vector");

      Int_Reader.Read (Doc, Arr, Out2, Cnt, St);
      Assert (St = Int_Reader.Read_Overflow, "vector overflow reported");

      Int_Reader.Read (Doc, DM.Add_String (Doc, To_Bytes ("x")), Out3, Cnt, St);
      Assert (St = Int_Reader.Read_Wrong_Kind, "non-array reported");
   end Test_Arrays_Reader;

   procedure Test_Extensions (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc      : DM.Document (16, 128);
      Contract : constant FLD.Field_Set := [F_Id, F_Name];
      Set      : Ext.Extension_Set (Capacity => 2, Name_Pool => 64);
      Added    : Boolean;
   begin
      Ext.Add (Set, Contract, To_Bytes ("extra"),
               DM.Add_Bool (Doc, True), Added);
      Assert (Added and then Ext.Count (Set) = 1, "unknown captured");
      Assert (Ext.Contains (Set, To_Bytes ("extra")), "contains name");
      Assert (To_Str (Ext.Name (Set, 1)) = "extra", "name preserved");

      --  A core field name may never become an extension (REP-INV-019).
      Ext.Add (Set, Contract, To_Bytes ("id"), DM.Add_Null (Doc), Added);
      Assert (not Added, "core field name refused as extension");

      Ext.Add (Set, Contract, To_Bytes ("more"), DM.Add_Null (Doc), Added);
      Assert (Added and then Ext.Is_Full (Set), "set now full");
      Ext.Add (Set, Contract, To_Bytes ("third"), DM.Add_Null (Doc), Added);
      Assert (not Added, "full set refuses further additions");
   end Test_Extensions;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Fields: descriptor", Test_Fields'Access));
      Suite.Add_Test
        (Caller.Create ("Objects: order-independent lookup",
         Test_Lookup_Order_Independent'Access));
      Suite.Add_Test
        (Caller.Create ("Objects: required fields",
         Test_Validate_Required'Access));
      Suite.Add_Test
        (Caller.Create ("Objects: unknown-member policy",
         Test_Validate_Unknown_Policy'Access));
      Suite.Add_Test
        (Caller.Create ("Objects: duplicate field",
         Test_Validate_Duplicate'Access));
      Suite.Add_Test
        (Caller.Create ("Objects: canonical-name encode",
         Test_Encode_Canonical_Names'Access));
      Suite.Add_Test
        (Caller.Create ("Arrays: typed reader", Test_Arrays_Reader'Access));
      Suite.Add_Test
        (Caller.Create ("Extensions: bounded capture", Test_Extensions'Access));
   end Add_Tests;

end Objects_Tests;
