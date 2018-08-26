external _stringify : Js.Json.t -> string = "JSON.stringify" [@@bs.val]

module Encode = struct
  include Json.Encode

  type 'a t = 'a -> Js.Json.t

  let make f = f

  let encode f x = f x

  let unit () = null

  let int64 s = string (Int64.to_string s)

  let int32 s = string (Int32.to_string s)

  type field = string * Js.Json.t

  let field ?default:_ encode ~name data = (name, encode data)

  let field_o ?default encode ~name data =
    if Belt.Option.isSome data
    then (name, data |. Belt.Option.getExn |. encode)
    else
      ( name
      , match default with
        | Some data ->
            encode data
        | None ->
            null )


  let obj = object_

  let constr0 = string

  let constr1 s f x = pair Json.Encode.string f (s, x)

  let contramap f g b = g (f b)

  let option_as_constr f = function
    | None ->
        constr0 "None"
    | Some s ->
        constr1 "Some" f s
end

module Decode = struct
  include Json.Decode

  let make f = f

  type 'a t = Js.Json.t -> 'a

  exception DecoderError of string

  let decode f json = f json

  let unit x =
    if Obj.magic x == Js.null
    then ()
    else raise (DecoderError ("Expected null, got " ^ _stringify x))


  let obj_array f json =
    match Js.Json.classify json with
    | JSONObject obj ->
        Js.Dict.entries obj |. Belt.Array.map (fun (k, v) -> (k, f v))
    | _ ->
        raise (DecoderError ("Expected object, got " ^ _stringify json))


  let obj_list f json =
    match Js.Json.classify json with
    | JSONObject obj ->
        Js.Dict.entries obj
        |. Belt.Array.map (fun (k, v) -> (k, f v))
        |. Belt.List.fromArray
    | _ ->
        raise (DecoderError ("Expected object, got " ^ _stringify json))


  let fieldOptional s f json =
    match Js.Json.classify json with
    | JSONObject obj ->
        Js.Dict.get obj s |. Belt.Option.map f
    | _ ->
        raise (DecoderError ("Expected object, got " ^ _stringify json))


  let fieldDefault s default f =
    fieldOptional s f
    |> map (function
           | None ->
               default
           | Some s ->
               s )


  let enum l json =
    match Js.Json.classify json with
    | JSONString s -> (
      match Belt.List.getAssoc l s ( = ) with
      | Some (`Single a) ->
          a
      | _ ->
          raise (DecoderError ("Expected string, got " ^ _stringify json)) )
    | JSONArray [|s; args|]
      when Js.typeof s = "string" -> (
      match Belt.List.getAssoc l (Obj.magic s) ( = ) with
      | Some (`Decode d) ->
          decode d args
      | _ ->
          raise
            (DecoderError ("Expected [string, 'a], got " ^ _stringify json)) )
    | _ ->
        raise
          (DecoderError
             ("Expected string or [string, 'a], got " ^ _stringify json))


  let option_as_constr f =
    enum [("None", `Single None); ("Some", `Decode (map (fun x -> Some x) f))]


  let nullable f json =
    Obj.magic json |. Js.Nullable.toOption |. Belt.Option.map f
end
