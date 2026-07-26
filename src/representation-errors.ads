--  Representation.Errors — the structured failure vocabulary (§11). Ordinary
--  malformed input, capacity exhaustion, unsupported versions, compatibility
--  failures, and I/O errors are values, never exceptions (Rule 4.6). Each
--  carries a top-level category and a stable, locale-neutral machine error
--  identifier. The identifier strings are contract-stable: never localise,
--  reword, or renumber them.
package Representation.Errors
  with Preelaborate
is

   type Error_Category is
     (Ok,
      Syntax_Error,             --  malformed textual codec token/grammar
      Structural_Error,         --  well-formed tokens, invalid structure
      Representation_Constraint, --  representation-level rule violated
      Unsupported_Version,      --  version outside supported range
      Compatibility_Failure,    --  schema/version compatibility rejected
      Capacity_Failure,         --  a limit or the work budget was exceeded
      IO_Failure,               --  input source or output sink failure
      Internal_Error);          --  a broken internal contract (a bug)

   --  Stable machine error identifiers (locale-neutral). Grouped by domain.
   Json_Invalid_Token    : constant String := "representation.json.invalid-token";
   Json_Invalid_Utf8     : constant String := "representation.json.invalid-utf8";
   Json_Invalid_Escape   : constant String := "representation.json.invalid-escape";
   Json_Invalid_Surrogate : constant String :=
     "representation.json.invalid-surrogate";
   Json_Trailing_Input   : constant String := "representation.json.trailing-input";
   Json_Invalid_Number   : constant String := "representation.json.invalid-number";
   Json_Unexpected_End   : constant String := "representation.json.unexpected-end";

   Object_Missing_Field  : constant String := "representation.object.missing-field";
   Object_Duplicate_Field : constant String :=
     "representation.object.duplicate-field";
   Object_Unknown_Field  : constant String := "representation.object.unknown-field";
   Field_Type_Mismatch   : constant String :=
     "representation.field.type-mismatch";

   Enum_Unknown_Symbol   : constant String := "representation.enum.unknown-symbol";
   Variant_Unknown       : constant String :=
     "representation.variant.unknown-discriminator";

   Version_Unsupported   : constant String := "representation.version.unsupported";
   Version_Downgrade     : constant String :=
     "representation.version.downgrade-refused";

   Number_Overflow       : constant String := "representation.number.overflow";
   Number_Too_Many_Digits : constant String :=
     "representation.number.too-many-digits";
   Number_Exponent_Range : constant String :=
     "representation.number.exponent-out-of-range";

   Limit_Max_Depth       : constant String := "representation.limit.maximum-depth";
   Limit_Max_Bytes       : constant String := "representation.limit.maximum-bytes";
   Limit_Max_Members     : constant String :=
     "representation.limit.maximum-members";
   Limit_Max_Elements    : constant String :=
     "representation.limit.maximum-elements";
   Limit_Work_Budget     : constant String := "representation.limit.work-budget";

   Io_Source_Failure     : constant String := "representation.io.source-failure";
   Io_Sink_Failure       : constant String := "representation.io.sink-failure";

   --  Sensitivity classification for field descriptors and diagnostics (§11,
   --  §34). Sensitive values are omitted from diagnostics by default
   --  (REP-INV-017).
   type Sensitivity_Class is
     (Public, Personal, Sensitive, Secret, Credential, Token);

   --  Values in these classes must never appear verbatim in diagnostics.
   function Is_Redacted (Class : Sensitivity_Class) return Boolean is
     (Class /= Public);

end Representation.Errors;
