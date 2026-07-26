--  Quickstart — the Phase 0 foundation API using public interfaces only.
--  Later phases add typed JSON codecs, schemas, versions, and migrations; this
--  example is exercised by the repository release checks.
with Ada.Text_IO; use Ada.Text_IO;

with Representation;
with Representation.Paths;
with Representation.Results;
with Representation.Errors;
with Representation.Diagnostics;
with Representation.Identifiers;

procedure Quickstart is
   P : Representation.Paths.Path;
begin
   Put_Line ("representation " & Representation.Library_Version);

   --  Build an authoritative structured location and render it deterministically.
   Representation.Paths.Push_Field (P, "users");
   Representation.Paths.Push_Index (P, 3);
   Representation.Paths.Push_Field (P, "email");
   Put_Line ("path:      " & Representation.Paths.Render (P));

   --  Ordinary failure is a value, not an exception (Rule 4.6).
   declare
      O : constant Representation.Results.Outcome :=
        Representation.Results.Failure
          (Representation.Errors.Structural_Error,
           Representation.Errors.Object_Missing_Field,
           "email is required");
   begin
      Put_Line
        ("outcome:   ok? "
         & Boolean'Image (Representation.Results.Is_Ok (O))
         & "  id=" & Representation.Results.Error_Identifier (O));
   end;

   --  A diagnostic is stamped with the structured path (REP-INV-016).
   declare
      D : constant Representation.Diagnostics.Diagnostic :=
        Representation.Diagnostics.Make
          (Level    => Representation.Diagnostics.Error,
           Category => Representation.Errors.Structural_Error,
           Error_Id => Representation.Errors.Object_Missing_Field,
           Path     => P,
           Message  => "missing required field");
   begin
      Put_Line
        ("diagnostic at " & Representation.Diagnostics.Path_Render (D)
         & ": " & Representation.Diagnostics.Message (D));
   end;

   --  Stable, locale-neutral identifiers (REP-INV-013).
   Put_Line
     ("field id:  "
      & Representation.Identifiers.Image
          (Representation.Identifiers.To_Field_Id ("users.user.email")));
end Quickstart;
