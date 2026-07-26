--  Representation.Optionals — a tri-state presence wrapper (§25, REP-INV-007).
--  A representation distinguishes three cases that lesser models conflate: a
--  member that is Absent (not present at all), one that is explicitly null, and
--  one that carries a Value. Keeping absent and null distinct preserves
--  patch/merge semantics; this generic makes the distinction a type.
generic
   type Element_Type is private;
package Representation.Optionals is

   type Presence is (Absent, Null_Present, Value_Present);

   type Optional is private;

   Nothing    : constant Optional;   --  Absent
   Null_Value : constant Optional;   --  present, explicitly null

   function To_Optional (Value : Element_Type) return Optional;

   function State (O : Optional) return Presence;
   function Is_Absent (O : Optional) return Boolean;
   function Is_Null (O : Optional) return Boolean;
   function Is_Value (O : Optional) return Boolean;

   --  The carried value; defined only when Is_Value (O).
   function Value (O : Optional) return Element_Type
     with Pre => Is_Value (O);

   --  The carried value, or Default when absent or null.
   function Value_Or (O : Optional; Default : Element_Type) return Element_Type;

private

   type Optional (State : Presence := Absent) is record
      case State is
         when Value_Present =>
            Data : Element_Type;
         when others =>
            null;
      end case;
   end record;

   Nothing    : constant Optional := (State => Absent);
   Null_Value : constant Optional := (State => Null_Present);

end Representation.Optionals;
