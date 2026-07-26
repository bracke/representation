--  Representation.Text — deterministic UTF-8 validation (§7.3, REP-INV-004).
--  Wire text is UTF-8; validation is host-locale-independent and rejects
--  overlong encodings, surrogate code points (U+D800..U+DFFF), and code points
--  above U+10FFFF. Both whole-buffer and incremental (streaming) forms share
--  one well-formed-UTF-8 state machine. Marked SPARK_Mode as a proof target.
package Representation.Text
  with Preelaborate, SPARK_Mode => On
is

   --  True iff Data is a complete, well-formed UTF-8 sequence.
   function Valid_Utf8 (Data : Byte_Array) return Boolean;

   --  Count of Unicode scalar values in Data, or 0 if Data is not valid UTF-8.
   function Scalar_Count_Of (Data : Byte_Array) return Scalar_Count;

   --  Incremental validator for streaming input: feed byte runs across calls.
   type Validator is private;

   type Feed_Result is (Feeding_Ok, Feeding_Invalid);

   function New_Validator return Validator;

   procedure Feed
     (V      : in out Validator;
      Data   : Byte_Array;
      Result : out Feed_Result);

   --  True only when the validator has not failed and no partial multibyte
   --  sequence is pending (i.e. the input so far is complete and well-formed).
   function Is_Complete (V : Validator) return Boolean;
   function Failed (V : Validator) return Boolean;

private

   type Validator is record
      Has_Failed : Boolean := False;
      Expected   : Natural := 0;        --  continuation bytes still required
      Lo         : Byte    := 16#80#;   --  allowed range for the next
      Hi         : Byte    := 16#BF#;   --  continuation byte
   end record;

end Representation.Text;
