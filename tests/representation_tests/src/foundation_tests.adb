with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Caller;

with Representation;                use Representation;
with Representation.Identifiers;
with Representation.Paths;
with Representation.Results;
with Representation.Errors;
with Representation.Diagnostics;
with Representation.Limits;
with Representation.Buffers;
with Representation.Inputs;
with Representation.Version;

package body Foundation_Tests is

   package Ids renames Representation.Identifiers;
   package RP renames Representation.Paths;

   --  REP-INV-013: stable identifier lexical rule.
   procedure Test_Identifiers (T : in out Fixture) is
      pragma Unreferenced (T);
   begin
      Assert (Ids.Valid_Identifier ("users.user.display-name"),
              "dotted-hyphen identifier is valid");
      Assert (Ids.Valid_Identifier ("a"), "single char is valid");
      Assert (not Ids.Valid_Identifier (""), "empty is invalid");
      Assert (not Ids.Valid_Identifier (".x"), "leading separator invalid");
      Assert (not Ids.Valid_Identifier ("x."), "trailing separator invalid");
      Assert (not Ids.Valid_Identifier ("a..b"), "doubled separator invalid");
      Assert (not Ids.Valid_Identifier ("a-.b"), "adjacent separators invalid");
      Assert (not Ids.Valid_Identifier ("Abc"), "uppercase invalid");
      Assert (not Ids.Valid_Identifier ("a b"), "space invalid");
      Assert (Ids.Image (Ids.To_Schema_Id ("users.user")) = "users.user",
              "schema id round-trips through Image");
   end Test_Identifiers;

   --  REP-INV-016: deterministic structured-path render.
   procedure Test_Path_Render (T : in out Fixture) is
      pragma Unreferenced (T);
      P : RP.Path;
   begin
      RP.Push_Field (P, "users");
      RP.Push_Index (P, 3);
      RP.Push_Field (P, "email");
      Assert (RP.Render (P) = "$.users[3].email",
              "render is $.users[3].email, got: " & RP.Render (P));
      Assert (Natural (RP.Depth (P)) = 3, "depth is 3");
      RP.Pop (P);
      Assert (RP.Render (P) = "$.users[3]", "pop drops last segment");
   end Test_Path_Render;

   procedure Test_Path_Bracket_And_Truncation (T : in out Fixture) is
      pragma Unreferenced (T);
      P : RP.Path;
   begin
      RP.Push_Field (P, "a.b");
      Assert (RP.Render (P) = "$[""a.b""]",
              "non-simple name uses bracket-quote form, got: " & RP.Render (P));
      RP.Clear (P);
      Assert (not RP.Truncated (P), "cleared path not truncated");
      for I in 1 .. RP.Max_Segments + 5 loop
         RP.Push_Field (P, "x");
      end loop;
      Assert (RP.Truncated (P), "overflow past capacity is marked truncated");
   end Test_Path_Bracket_And_Truncation;

   procedure Test_Results (T : in out Fixture) is
      pragma Unreferenced (T);
      use type Representation.Errors.Error_Category;
      Ok  : constant Representation.Results.Outcome :=
        Representation.Results.Success;
      Bad : constant Representation.Results.Outcome :=
        Representation.Results.Failure
          (Representation.Errors.Syntax_Error,
           Representation.Errors.Json_Invalid_Token,
           "unexpected token");
   begin
      Assert (Representation.Results.Is_Ok (Ok), "Success is ok");
      Assert (not Representation.Results.Is_Ok (Bad), "Failure is not ok");
      Assert (Representation.Results.Category (Bad) =
                Representation.Errors.Syntax_Error, "category preserved");
      Assert (Representation.Results.Error_Identifier (Bad) =
                "representation.json.invalid-token", "error id preserved");
      Assert (Representation.Results.Message (Bad) = "unexpected token",
              "message preserved");
   end Test_Results;

   procedure Test_Diagnostics (T : in out Fixture) is
      pragma Unreferenced (T);
      P   : RP.Path;
      Set : Representation.Diagnostics.Diagnostic_Set;
      D   : Representation.Diagnostics.Diagnostic;
   begin
      RP.Push_Field (P, "email");
      D := Representation.Diagnostics.Make
        (Level    => Representation.Diagnostics.Error,
         Category => Representation.Errors.Structural_Error,
         Error_Id => Representation.Errors.Object_Missing_Field,
         Path     => P,
         Message  => "required");
      Representation.Diagnostics.Add (Set, D, Capacity => 2);
      Representation.Diagnostics.Add (Set, D, Capacity => 2);
      Representation.Diagnostics.Add (Set, D, Capacity => 2);  --  over capacity
      Assert (Natural (Representation.Diagnostics.Count (Set)) = 2,
              "bounded to capacity");
      Assert (Representation.Diagnostics.Truncated (Set),
              "overflow reported as truncated");
      Assert (Representation.Diagnostics.Path_Render
                (Representation.Diagnostics.Element (Set, 1)) = "$.email",
              "diagnostic carries the structured path render");
   end Test_Diagnostics;

   procedure Test_Limits (T : in out Fixture) is
      pragma Unreferenced (T);
      use Representation.Limits;
   begin
      Assert (Strict_Limits.Max_Depth < Default_Limits.Max_Depth,
              "strict depth tighter than default");
      Assert (Strict_Limits.Max_Extensions = 0,
              "strict profile disables extensions");
      Assert (Default_Limits.Work_Budget > 0, "work budget positive");
   end Test_Limits;

   procedure Test_Buffers (T : in out Fixture) is
      pragma Unreferenced (T);
      B : Representation.Buffers.Buffer (Capacity => 4);
      Over : Boolean;
   begin
      Representation.Buffers.Append (B, Byte_Array'(1, 2, 3), Over);
      Assert (not Over, "append within capacity");
      Assert (Natural (Representation.Buffers.Length (B)) = 3, "length 3");
      Representation.Buffers.Append (B, Byte_Array'(4, 5), Over);
      Assert (Over, "append past capacity overflows and writes nothing");
      Assert (Natural (Representation.Buffers.Length (B)) = 3,
              "length unchanged after overflow");
      Assert (Representation.Buffers.To_Byte_Array (B) = Byte_Array'(1, 2, 3),
              "buffer contents preserved");
   end Test_Buffers;

   procedure Test_Array_Source (T : in out Fixture) is
      pragma Unreferenced (T);
      use type Representation.Inputs.Read_Status;
      Data : aliased constant Byte_Array := [10, 20, 30];
      Src  : Representation.Inputs.Array_Source (Data'Access);
      Buf  : Byte_Array (1 .. 2);
      Last : Natural;
      St   : Representation.Inputs.Read_Status;
   begin
      Representation.Inputs.Read (Src, Buf, Last, St);
      Assert (St = Representation.Inputs.Read_Ok and then Last = 2,
              "first read yields two bytes");
      Assert (Buf (1) = 10 and then Buf (2) = 20, "bytes read in order");
      Representation.Inputs.Read (Src, Buf, Last, St);
      Assert (St = Representation.Inputs.Read_Ok and then Last = 1,
              "second read yields the last byte");
      Assert (Buf (1) = 30, "third byte read");
      Representation.Inputs.Read (Src, Buf, Last, St);
      Assert (St = Representation.Inputs.Read_End, "then end of input");
   end Test_Array_Source;

   procedure Test_Version (T : in out Fixture) is
      pragma Unreferenced (T);
      use Representation.Version;
   begin
      Assert (Image (7) = "7", "version image has no leading blank");
      Assert (Is_Active (2, Introduced => 1), "v2 active from v1");
      Assert (not Is_Active (1, Introduced => 2), "v1 not active before v2");
      Assert (not Is_Active (3, Introduced => 1, Removed => 3),
              "removal bound is exclusive");
   end Test_Version;

   package Caller is new AUnit.Test_Caller (Fixture);

   procedure Add_Tests (Suite : AUnit.Test_Suites.Access_Test_Suite) is
   begin
      Suite.Add_Test
        (Caller.Create ("Foundation: identifiers", Test_Identifiers'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: path render", Test_Path_Render'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: path bracket + truncation",
         Test_Path_Bracket_And_Truncation'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: results", Test_Results'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: diagnostics", Test_Diagnostics'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: limits", Test_Limits'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: buffers", Test_Buffers'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: array source", Test_Array_Source'Access));
      Suite.Add_Test
        (Caller.Create ("Foundation: version", Test_Version'Access));
   end Add_Tests;

end Foundation_Tests;
