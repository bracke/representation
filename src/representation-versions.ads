--  Representation.Versions — a bounded, caller-owned registry of the contract
--  versions a consumer supports (§35). It names the Current version and the set
--  of older versions it can accept (via migration). Resolve classifies an
--  incoming version without ever silently downgrading: a version newer than
--  Current is refused as Version_Too_New rather than treated as Current, and an
--  unrecognised version is Version_Unsupported (REP-INV-015). Built
--  incrementally then Finalized; a finalized set is immutable.
with Representation.Version;
package Representation.Versions is

   subtype Version_Number is Representation.Version.Version_Number;

   type Version_Set (Capacity : Natural) is limited private;

   procedure Start (VS : in out Version_Set; Current : Version_Number);

   --  Register an accepted older version. Added is False if the set is final,
   --  full, or V is >= Current (only strictly older versions are added here;
   --  Current is implicitly supported).
   procedure Add_Supported
     (VS : in out Version_Set; V : Version_Number; Added : out Boolean);

   procedure Finalize (VS : in out Version_Set);
   function Is_Final (VS : Version_Set) return Boolean;

   function Current (VS : Version_Set) return Version_Number;
   function Is_Supported (VS : Version_Set; V : Version_Number) return Boolean;

   type Resolution is
     (Version_Current,      --  V is the current version; use data directly
      Version_Migratable,   --  V is an accepted older version; migrate to Current
      Version_Too_New,      --  V is newer than Current; refuse (never downgrade)
      Version_Unsupported); --  V is unrecognised

   function Resolve (VS : Version_Set; V : Version_Number) return Resolution;

private

   type Version_Array is array (Positive range <>) of Version_Number;

   type Version_Set (Capacity : Natural) is limited record
      Cur      : Version_Number := Version_Number'First;
      Older    : Version_Array (1 .. Capacity);
      N        : Natural := 0;
      Final    : Boolean := False;
      Started  : Boolean := False;
   end record;

end Representation.Versions;
