--  Representation.Paths — structured, bounded location paths (§11). Diagnostics
--  carry a structured path, not only a rendered string; the structure is
--  authoritative and the render (e.g. "$.users[3].email") is derived
--  deterministically. Paths are a bounded push/pop stack built during
--  traversal; overflow past capacity is recorded and marked in the render
--  rather than growing without bound (Rule 4.4).
package Representation.Paths
  with Preelaborate
is

   type Segment_Kind is
     (Field_Segment, Index_Segment, Variant_Segment, Extension_Segment);

   Max_Segment_Name : constant := 128;
   Max_Segments     : constant := 128;

   type Path is private;

   Empty_Path : constant Path;

   procedure Clear (P : out Path);

   --  Logical depth of recorded segments (bounded by Max_Segments).
   function Depth (P : Path) return Path_Depth;

   --  True once a push has been dropped because the path was at capacity; the
   --  render marks the truncation with a trailing marker.
   function Truncated (P : Path) return Boolean;

   procedure Push_Field     (P : in out Path; Name  : String);
   procedure Push_Index     (P : in out Path; Index : Array_Index);
   procedure Push_Variant   (P : in out Path; Name  : String);
   procedure Push_Extension (P : in out Path; Name  : String);
   procedure Pop            (P : in out Path);

   --  Deterministic JSONPath-style render. Field names that are simple
   --  identifiers render as ".name"; anything else renders in bracket-quote
   --  form (e.g. $["a.b"]) with '"' and '\' escaped.
   function Render (P : Path) return String;

private

   subtype Name_Length_Range is Natural range 0 .. Max_Segment_Name;
   subtype Segment_Count is Natural range 0 .. Max_Segments;

   type Segment (Kind : Segment_Kind := Field_Segment) is record
      case Kind is
         when Field_Segment | Variant_Segment | Extension_Segment =>
            Name_Length : Name_Length_Range := 0;
            Name        : String (1 .. Max_Segment_Name) := [others => ' '];
         when Index_Segment =>
            Index : Array_Index := 0;
      end case;
   end record;

   type Segment_Array is array (1 .. Max_Segments) of Segment;

   type Path is record
      Count     : Segment_Count := 0;
      Dropped   : Boolean       := False;
      Items     : Segment_Array;
   end record;

   Empty_Path : constant Path :=
     (Count => 0, Dropped => False, Items => <>);

end Representation.Paths;
