open Jest

type 'a test =
  { name : string
  ; to_json : 'a -> Js.Json.t
  ; of_json : Js.Json.t -> 'a
  ; data : 'a }

type test' = T : 'a test -> test'

let test_decode ~name ~json ~buckle ~data =
  T
    { name
    ; to_json = Atdgen_codec_runtime.Encode.encode json
    ; of_json = Atdgen_codec_runtime.Decode.decode buckle
    ; data }


let test_encode ~name ~json ~buckle ~data =
  T
    { name
    ; to_json = Atdgen_codec_runtime.Encode.encode buckle
    ; of_json = Atdgen_codec_runtime.Decode.decode json
    ; data }


let run_test (T t) =
  let open Expect in
  let open! Expect.Operators in
  let json = t.to_json t.data in
  let data' = t.of_json json in
  test t.name (fun () -> expect t.data |> toEqual data')


let run_tests tests = List.iter run_test tests

let _ =
  describe "tests" (fun () ->
      run_tests
        [ test_decode
            ~name:"decode record"
            ~json:Bucklespec_bs.write_labeled
            ~buckle:Bucklespec_bs.read_labeled
            ~data:{Bucklespec_t.flag = false; lb = "foo bar"; count = 123}
        ; test_encode
            ~name:"encode record"
            ~json:Bucklespec_bs.read_labeled
            ~buckle:Bucklespec_bs.write_labeled
            ~data:{Bucklespec_t.flag = false; lb = "foo bar"; count = 123}
        ; test_decode
            ~name:"decode variant"
            ~json:Bucklespec_bs.write_simple_vars
            ~buckle:Bucklespec_bs.read_simple_vars
            ~data:[`Foo (123, 456); `Bar; `Foobar (); `Foo_id (`Id "testing")]
        ; test_encode
            ~name:"encode variant"
            ~json:Bucklespec_bs.read_simple_vars
            ~buckle:Bucklespec_bs.write_simple_vars
            ~data:[`Foo (123, 456); `Bar; `Foobar (); `Foo_id (`Id "testing")]
        ] )

    
