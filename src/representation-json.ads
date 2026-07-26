--  Representation.JSON — the JSON wire codec, the only required concrete V1
--  codec (§22). Child packages provide the incremental tokenizer (.Lexer),
--  the parser, and typed/document integration. The abstraction above is codec-
--  neutral; JSON is one instance of it.
package Representation.JSON
  with Pure
is
end Representation.JSON;
