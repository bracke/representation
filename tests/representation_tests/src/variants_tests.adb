with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;             use Representation;
with Representation.Documents;
with Representation.Identifiers;
with Representation.Fields;
with Representation.Variants;
with Representation.References;

package body Variants_Tests is

   package DM renames Representation.Documents;
   package Ids renames Representation.Identifiers;
   package FLD renames Representation.Fields;
   package Ref renames Representation.References;
   use type DM.Node_Kind;
   use type DM.Node_Ref;
   use type Ref.Reference_Status;

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

   type Shape_Tag is (Circle, Square);
   function Shape_Symbol (Tag : Shape_Tag) return String is
     (case Tag is when Circle => "circle", when Square => "square");
   package Shapes is new Representation.Variants (Shape_Tag, Shape_Symbol);
   use type Shapes.Dispatch_Status;

   function Discriminator return FLD.Field_Descriptor is
     (FLD.Make (Ids.To_Field_Id ("type")));

   function Shape_Obj
     (Doc : in out DM.Document; Type_Node : DM.Node_Ref) return DM.Node_Ref
   is
      O : constant DM.Node_Ref := DM.Add_Object (Doc);
   begin
      if Type_Node /= DM.No_Node then
         DM.Insert (Doc, O, To_Bytes ("type"), Type_Node);
      end if;
      return O;
   end Shape_Obj;

   procedure Test_Dispatch (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : DM.Document (16, 128);
      O   : constant DM.Node_Ref :=
        Shape_Obj (Doc, DM.Add_String (Doc, To_Bytes ("square")));
      Tag : Shape_Tag;
      St  : Shapes.Dispatch_Status;
   begin
      Shapes.Dispatch (Doc, O, Discriminator, Tag, St);
      Assert (St = Shapes.Variant_Ok and then Tag = Square,
              "dispatch to declared variant");
   end Test_Dispatch;

   procedure Test_Dispatch_Errors (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc     : DM.Document (32, 256);
      Unknown : constant DM.Node_Ref :=
        Shape_Obj (Doc, DM.Add_String (Doc, To_Bytes ("triangle")));
      Missing : constant DM.Node_Ref := Shape_Obj (Doc, DM.No_Node);
      Wrong   : constant DM.Node_Ref :=
        Shape_Obj (Doc, DM.Add_Number (Doc, To_Bytes ("5")));
      Tag : Shape_Tag;
      St  : Shapes.Dispatch_Status;
   begin
      Shapes.Dispatch (Doc, Unknown, Discriminator, Tag, St);
      Assert (St = Shapes.Variant_Unknown,
              "undeclared discriminator never mapped to a default");
      Shapes.Dispatch (Doc, Missing, Discriminator, Tag, St);
      Assert (St = Shapes.Variant_Missing_Discriminator, "missing discriminator");
      Shapes.Dispatch (Doc, Wrong, Discriminator, Tag, St);
      Assert (St = Shapes.Variant_Wrong_Kind, "non-string discriminator");
   end Test_Dispatch_Errors;

   procedure Test_Put_Discriminator (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc : DM.Document (16, 128);
      O   : constant DM.Node_Ref := DM.Add_Object (Doc);
      Tag : Shape_Tag;
      St  : Shapes.Dispatch_Status;
   begin
      Shapes.Put_Discriminator (Doc, O, Discriminator, Circle);
      Assert (To_Str (DM.Member_Key (Doc, O, 1)) = "type", "discriminator key");
      --  Round-trips back to the same tag.
      Shapes.Dispatch (Doc, O, Discriminator, Tag, St);
      Assert (St = Shapes.Variant_Ok and then Tag = Circle, "round-trips");
   end Test_Put_Discriminator;

   procedure Test_References (T : in out Fixture) is
      pragma Unreferenced (T);
      Doc  : DM.Document (16, 2048);
      R    : Ref.Reference;
      St   : Ref.Reference_Status;
      Big  : constant Byte_Array (1 .. Ref.Max_Reference_Length + 1) :=
        [others => Byte (Character'Pos ('x'))];
      Node : DM.Node_Ref;
   begin
      Ref.Make (To_Bytes ("/users/7"), R, St);
      Assert (St = Ref.Reference_Ok and then not Ref.Is_Null (R)
              and then To_Str (Ref.Target (R)) = "/users/7", "make reference");

      Ref.Make (To_Bytes (""), R, St);
      Assert (St = Ref.Reference_Empty, "empty rejected");
      Ref.Make (Big, R, St);
      Assert (St = Ref.Reference_Too_Long, "over-long rejected");

      --  Round-trip through a document string node.
      Ref.Make (To_Bytes ("/a/b"), R, St);
      Node := Ref.Encode (Doc, R);
      Assert (DM.Kind (Doc, Node) = DM.String_Node, "encoded as string");
      Ref.Decode (Doc, Node, R, St);
      Assert (St = Ref.Reference_Ok and then To_Str (Ref.Target (R)) = "/a/b",
              "decode round-trips");
      Ref.Decode (Doc, DM.Add_Number (Doc, To_Bytes ("1")), R, St);
      Assert (St = Ref.Reference_Wrong_Kind, "number is not a reference");
   end Test_References;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test (Caller.Create ("Variants: dispatch", Test_Dispatch'Access));
      Suite.Add_Test
        (Caller.Create ("Variants: dispatch errors",
         Test_Dispatch_Errors'Access));
      Suite.Add_Test
        (Caller.Create ("Variants: put discriminator",
         Test_Put_Discriminator'Access));
      Suite.Add_Test
        (Caller.Create ("References: make/encode/decode",
         Test_References'Access));
   end Add_Tests;

end Variants_Tests;
