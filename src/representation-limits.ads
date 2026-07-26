--  Representation.Limits — explicit finite work limits carried by every
--  decoding and migration context (§10). There is deliberately no unbounded
--  default for untrusted input: limits are enforced before any prohibited
--  growth (REP-INV-005), and a deterministic work budget guards against
--  pathological inputs that stay within the structural limits.
package Representation.Limits
  with Preelaborate
is

   type Limits is record
      Max_Input_Bytes    : Byte_Count     := 8 * 1024 * 1024;
      Max_Depth          : Depth_Count    := 64;
      Max_Object_Members : Field_Count    := 4_096;
      Max_Array_Elements : Element_Count  := 65_536;
      Max_Total_Values   : Value_Count    := 262_144;
      Max_String_Bytes   : Byte_Count     := 1 * 1024 * 1024;
      Max_Scalars        : Scalar_Count   := 1_048_576;
      Max_Byte_String    : Byte_Count     := 1 * 1024 * 1024;
      Max_Number_Digits  : Digit_Count    := 128;
      Max_Exponent       : Exponent_Value := 4_096;
      Max_Extensions     : Field_Count    := 256;
      Max_Diagnostics    : Field_Count    := 64;
      Max_Path_Depth     : Path_Depth     := 64;
      Work_Budget        : Value_Count    := 4_194_304;
   end record;

   --  Safe general-purpose profile for untrusted input.
   Default_Limits : constant Limits := (others => <>);

   --  Tight profile for security-sensitive closed contracts (§34): extensions
   --  disabled, small structural bounds, redacted-by-default diagnostics.
   Strict_Limits : constant Limits :=
     (Max_Input_Bytes    => 65_536,
      Max_Depth          => 16,
      Max_Object_Members => 64,
      Max_Array_Elements => 1_024,
      Max_Total_Values   => 4_096,
      Max_String_Bytes   => 16_384,
      Max_Scalars        => 16_384,
      Max_Byte_String    => 16_384,
      Max_Number_Digits  => 40,
      Max_Exponent       => 64,
      Max_Extensions     => 0,
      Max_Diagnostics    => 16,
      Max_Path_Depth     => 16,
      Work_Budget        => 262_144);

end Representation.Limits;
