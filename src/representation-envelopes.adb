package body Representation.Envelopes is

   package DM renames Representation.Documents;
   use type DM.Node_Ref;

   function Key (S : String) return Byte_Array is
      R : Byte_Array (1 .. S'Length);
   begin
      for I in S'Range loop
         R (I - S'First + 1) := Byte (Character'Pos (S (I)));
      end loop;
      return R;
   end Key;

   procedure Put
     (Doc : in out DM.Document; Obj : DM.Node_Ref;
      Name : String; Value : DM.Node_Ref) is
   begin
      if Value /= DM.No_Node then
         DM.Insert (Doc, Obj, Key (Name), Value);
      end if;
   end Put;

   function Build
     (Doc    : in out DM.Document;
      Data   : DM.Node_Ref;
      Meta   : DM.Node_Ref := DM.No_Node;
      Links  : DM.Node_Ref := DM.No_Node;
      Page   : DM.Node_Ref := DM.No_Node;
      Errors : DM.Node_Ref := DM.No_Node) return DM.Node_Ref
   is
      Env : constant DM.Node_Ref := DM.Add_Object (Doc);
   begin
      Put (Doc, Env, "data", Data);
      Put (Doc, Env, "meta", Meta);
      Put (Doc, Env, "links", Links);
      Put (Doc, Env, "page", Page);
      Put (Doc, Env, "errors", Errors);
      return Env;
   end Build;

   function Data
     (Doc : DM.Document; Env : DM.Node_Ref) return DM.Node_Ref is
     (DM.Find (Doc, Env, Key ("data")));
   function Meta
     (Doc : DM.Document; Env : DM.Node_Ref) return DM.Node_Ref is
     (DM.Find (Doc, Env, Key ("meta")));
   function Links
     (Doc : DM.Document; Env : DM.Node_Ref) return DM.Node_Ref is
     (DM.Find (Doc, Env, Key ("links")));
   function Page
     (Doc : DM.Document; Env : DM.Node_Ref) return DM.Node_Ref is
     (DM.Find (Doc, Env, Key ("page")));
   function Errors
     (Doc : DM.Document; Env : DM.Node_Ref) return DM.Node_Ref is
     (DM.Find (Doc, Env, Key ("errors")));

   function Has_Errors
     (Doc : DM.Document; Env : DM.Node_Ref) return Boolean
   is
      E : constant DM.Node_Ref := Errors (Doc, Env);
   begin
      return E /= DM.No_Node and then DM.Length (Doc, E) > 0;
   end Has_Errors;

end Representation.Envelopes;
