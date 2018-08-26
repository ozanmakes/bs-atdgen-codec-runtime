# bs-atdgen-codec-runtime
Runtime for using
[atdgen](https://github.com/mjambon/atd/) and
[BuckleScript](https://bucklescript.github.io/) together.

## Installation
```sh
$ yarn add @osener/bs-atdgen-codec-runtime
```

Then add @glennsl/bs-json to bs-dependencies in your bsconfig.json:

```json
{
  ...
  "bs-dependencies": ["@osener/bs-atdgen-codec-runtime"]
}
```

You will also need development version of atdgen:

```sh 
$ opam pin add --yes https://github.com/mjambon/atd.git
```

## Usage
Create an `.atd` file:

```ml
(* protocol.atd *)

type pet = [
  | Cat of string
  | Dog of string    
  ]

type person =
  { name : string
  ; age : int
  ; ~student : bool
  ; ?pet : pet option 
  }

type request =
  [ Greeting of person ]

```

Use `atdgen` to generate your types and BuckleScript parsers:
```sh
# Generate protocol_t.[ml/mli] and protocol_bs.[ml/mli] 
$ atdgen -t protocol.atd && atdgen -bs -open Protocol_t protocol.atd
$ atdgen -bs -open Protocol_t protocol.atd
```

Finally, use the generated modules for parsing and serialization:
#### OCaml
```ml
(** Parse JSON string *)
let () =
  let request =
    {| ["Greeting",{"name":"Turner","age":33,"pet":["Dog","Hooch"]}] |}
    |> Json.parseOrRaise
    |> Atdgen_codec_runtime.Decode.decode Protocol_bs.read_request
  in
  match request with `Greeting {name; _} -> Js.log ("Hi " ^ name ^ "!")


(** Serialize [request] as JSON *)
let () =
  let request =
    `Greeting
      { Protocol_t.name = "Turner"
      ; age = 33
      ; student = false
      ; pet = Some (`Dog "Hooch") }
  in
  request
  |> Atdgen_codec_runtime.Encode.encode Protocol_bs.write_request
  |> Json.stringify
  |> Js.log2 "JSON:"
```

#### Reason

```reason
/** Parse JSON string */
let () = {
  let request =
    {| ["Greeting",{"name":"Turner","age":33,"pet":["Dog","Hooch"]}] |}
    |> Json.parseOrRaise
    |> Atdgen_codec_runtime.Decode.decode(Protocol_bs.read_request);

  switch (request) {
  | `Greeting({name, _}) => Js.log("Hi " ++ name ++ "!")
  };
};

/** Serialize [request] as JSON */

let () = {
  let request =
    `Greeting({
      Protocol_t.name: "Turner",
      age: 33,
      student: false,
      pet: Some(`Dog("Hooch")),
    });

  request
  |> Atdgen_codec_runtime.Encode.encode(Protocol_bs.write_request)
  |> Json.stringify
  |> Js.log2("JSON:");
};

```
