--  Representation.Pagination — a bounded pagination descriptor (§38): page
--  size, offset, total, a has-more flag, and an optional opaque cursor. A plain
--  value with a fixed cursor buffer; it renders to and reads from a JSON object
--  with the canonical members limit / offset / total / has_more / cursor.
with Representation.Documents;
package Representation.Pagination is

   Max_Cursor : constant := 256;

   type Page is private;

   Empty_Page : constant Page;

   function Make
     (Limit    : Natural := 0;
      Offset   : Natural := 0;
      Total    : Natural := 0;
      Has_More : Boolean := False) return Page;

   function Limit (P : Page) return Natural;
   function Offset (P : Page) return Natural;
   function Total (P : Page) return Natural;
   function Has_More (P : Page) return Boolean;
   function Cursor (P : Page) return Byte_Array;

   --  Set the opaque cursor. Ok is False if it exceeds Max_Cursor.
   procedure Set_Cursor (P : in out Page; Value : Byte_Array; Ok : out Boolean);

   function To_Object
     (P : Page; Doc : in out Representation.Documents.Document)
      return Representation.Documents.Node_Ref;

   --  Read a pagination object. Ok is False if a present member has the wrong
   --  type; absent members keep their defaults.
   procedure From_Object
     (Doc : Representation.Documents.Document;
      Obj : Representation.Documents.Node_Ref;
      P   : out Page;
      Ok  : out Boolean);

private

   subtype Cursor_Range is Natural range 0 .. Max_Cursor;

   type Page is record
      Limit      : Natural := 0;
      Offset     : Natural := 0;
      Total      : Natural := 0;
      Has_More   : Boolean := False;
      Cursor_Len : Cursor_Range := 0;
      Cursor     : Byte_Array (1 .. Max_Cursor) := [others => 0];
   end record;

   Empty_Page : constant Page :=
     (Limit => 0, Offset => 0, Total => 0, Has_More => False,
      Cursor_Len => 0, Cursor => [others => 0]);

end Representation.Pagination;
