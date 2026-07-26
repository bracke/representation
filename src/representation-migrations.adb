package body Representation.Migrations is

   use type Version_Number;

   procedure Start (MS : in out Migration_Set) is
   begin
      MS.N := 0;
      MS.Final := False;
   end Start;

   --  Index of the (unique) step leaving From, or 0.
   function Outgoing (MS : Migration_Set; From : Version_Number) return Natural is
   begin
      for I in 1 .. MS.N loop
         if MS.Steps (I).From_V = From then
            return I;
         end if;
      end loop;
      return 0;
   end Outgoing;

   procedure Add_Step
     (MS           : in out Migration_Set;
      From_Version : Version_Number;
      To_Version   : Version_Number;
      Apply        : Transform;
      Added        : out Boolean) is
   begin
      Added := False;
      if MS.Final or else MS.N >= MS.Capacity
        or else To_Version <= From_Version
        or else Apply = null
        or else Outgoing (MS, From_Version) /= 0
      then
         return;
      end if;
      MS.N := MS.N + 1;
      MS.Steps (MS.N) := (From_V => From_Version, To_V => To_Version,
                          Apply => Apply);
      Added := True;
   end Add_Step;

   procedure Finalize (MS : in out Migration_Set) is
   begin
      MS.Final := True;
   end Finalize;

   function Is_Final (MS : Migration_Set) return Boolean is (MS.Final);

   function Step_Count (MS : Migration_Set) return Natural is (MS.N);

   function Plan
     (MS           : Migration_Set;
      From_Version : Version_Number;
      To_Version   : Version_Number) return Plan_Status
   is
      Current : Version_Number := From_Version;
      Hops    : Natural := 0;
   begin
      loop
         if Current = To_Version then
            return Plan_Ok;
         end if;
         declare
            Idx : constant Natural := Outgoing (MS, Current);
         begin
            if Idx = 0 or else MS.Steps (Idx).To_V > To_Version then
               return Plan_No_Path;
            end if;
            Current := MS.Steps (Idx).To_V;
         end;
         Hops := Hops + 1;
         if Hops > MS.N then
            return Plan_Cycle;   --  defensive; forward-only steps cannot cycle
         end if;
      end loop;
   end Plan;

   procedure Migrate
     (MS           : Migration_Set;
      Doc          : in out Representation.Documents.Document;
      Root         : in out Representation.Documents.Node_Ref;
      From_Version : Version_Number;
      To_Version   : Version_Number;
      Status       : out Migrate_Status)
   is
      Current : Version_Number := From_Version;
      Hops    : Natural := 0;
   begin
      loop
         if Current = To_Version then
            Status := Migrate_Ok;
            return;
         end if;
         declare
            Idx : constant Natural := Outgoing (MS, Current);
         begin
            if Idx = 0 or else MS.Steps (Idx).To_V > To_Version then
               Status := Migrate_No_Path;
               return;
            end if;
            declare
               Ok : Boolean;
            begin
               MS.Steps (Idx).Apply (Doc, Root, Ok);
               if not Ok then
                  Status := Migrate_Failed;
                  return;
               end if;
            end;
            Current := MS.Steps (Idx).To_V;
         end;
         Hops := Hops + 1;
         if Hops > MS.N then
            Status := Migrate_Cycle;
            return;
         end if;
      end loop;
   end Migrate;

end Representation.Migrations;
