let write_from_module_a =
  Atdgen_codec_runtime.Encode.make (function
      | A_t.Foo ->
          Obj.magic "Foo"
      | Bar ->
          Obj.magic "Bar" )


let read_from_module_a =
  Atdgen_codec_runtime.Decode.enum
    [("Foo", `Single A_t.Foo); ("Bar", `Single A_t.Bar)]
