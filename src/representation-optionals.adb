package body Representation.Optionals is

   function To_Optional (Value : Element_Type) return Optional is
     (State => Value_Present, Data => Value);

   function State (O : Optional) return Presence is (O.State);

   function Is_Absent (O : Optional) return Boolean is (O.State = Absent);
   function Is_Null (O : Optional) return Boolean is (O.State = Null_Present);
   function Is_Value (O : Optional) return Boolean is (O.State = Value_Present);

   function Value (O : Optional) return Element_Type is (O.Data);

   function Value_Or (O : Optional; Default : Element_Type) return Element_Type is
     (if O.State = Value_Present then O.Data else Default);

end Representation.Optionals;
