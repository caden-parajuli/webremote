let ( let* ) = Option.bind
let ( let+ ) = Result.bind

type connection = C.Type.dbus_connection Ctypes.structure Ctypes.ptr

let dbus_type_of_int ty =
  let open C.Type in
  match ty with
  | t when t = dbus_type_byte -> Dbus_type_byte
  | t when t = dbus_type_boolean -> Dbus_type_boolean
  | t when t = dbus_type_int16 -> Dbus_type_int16
  | t when t = dbus_type_uint16 -> Dbus_type_uint16
  | t when t = dbus_type_int32 -> Dbus_type_int32
  | t when t = dbus_type_uint32 -> Dbus_type_uint32
  | t when t = dbus_type_int64 -> Dbus_type_int64
  | t when t = dbus_type_uint64 -> Dbus_type_uint64
  | t when t = dbus_type_double -> Dbus_type_double
  | t when t = dbus_type_string -> Dbus_type_string
  | t when t = dbus_type_object_path -> Dbus_type_object_path
  | t when t = dbus_type_signature -> Dbus_type_signature
  | t when t = dbus_type_unix_fd -> Dbus_type_unix_fd
  | t when t = dbus_type_array -> Dbus_type_array
  | t when t = dbus_type_variant -> Dbus_type_variant
  | t when t = dbus_type_struct -> Dbus_type_struct
  | t when t = dbus_type_dict_entry -> Dbus_type_dict_entry
  | _ -> Dbus_type_invalid

let string_of_dbus_type ty =
  let open C.Type in
  match ty with
  | Dbus_type_byte -> "byte"
  | Dbus_type_boolean -> "boolean"
  | Dbus_type_int16 -> "int16"
  | Dbus_type_uint16 -> "uint16"
  | Dbus_type_int32 -> "int32"
  | Dbus_type_uint32 -> "uint32"
  | Dbus_type_int64 -> "int64"
  | Dbus_type_uint64 -> "uint64"
  | Dbus_type_double -> "double"
  | Dbus_type_string -> "string"
  | Dbus_type_object_path -> "object_path"
  | Dbus_type_signature -> "signature"
  | Dbus_type_unix_fd -> "unix_fd"
  | Dbus_type_array -> "array"
  | Dbus_type_variant -> "variant"
  | Dbus_type_struct -> "struct"
  | Dbus_type_dict_entry -> "dict_entry"
  | _ -> "invalid"

let connect () =
  let open C.Functions in
  let open C.Type in
  let* conn = dbus_bus_get DBUS_BUS_SESSION None in
  dbus_connection_set_exit_on_disconnect conn dbus_false;
  Gc.finalise (fun c -> dbus_connection_unref c) conn;

  Some conn

let get_busses connection =
  let open C.Functions in
  let open C.Type in
  let message =
    dbus_message_new_method_call "org.freedesktop.DBus" "/org/freedesktop/DBus"
      "org.freedesktop.DBus" "ListNames"
  in
  let response =
    dbus_connection_send_with_reply_and_block connection message
      dbus_timeout_use_default None
  in

  let+ () =
    match dbus_message_get_signature response with
    | "as" -> Ok ()
    | _ -> Error "Bad response signature"
  in

  let outer_iter = Ctypes.allocate_n dbus_message_iter ~count:1 in
  let+ () =
    match dbus_message_iter_init response outer_iter with
    | r when r = dbus_false -> Error "Could not initialize message iter"
    | _ -> Ok ()
  in

  let+ () =
    match dbus_message_iter_get_arg_type outer_iter with
    | ty when ty = dbus_type_array -> Ok ()
    | ty ->
        Error
          ("Response arg type is "
          ^ (string_of_dbus_type @@ dbus_type_of_int ty)
          ^ " instead of array")
  in

  let+ () =
    match dbus_message_iter_get_element_type outer_iter with
    | ty when ty = dbus_type_string -> Ok ()
    | ty ->
        Error
          ("Response arg type is an array of"
          ^ (string_of_dbus_type @@ dbus_type_of_int ty)
          ^ " instead of array of string")
  in

  (* todo: check element type is string *)
  let array_iter = Ctypes.allocate_n dbus_message_iter ~count:1 in
  let () = dbus_message_iter_recurse outer_iter array_iter in

  let get_next_string () =
    let open Ctypes in
    match dbus_message_iter_get_arg_type array_iter with
    | ty when ty = dbus_type_string ->
        let strp = allocate string "" in
        let vp = to_voidp strp in

        let () = dbus_message_iter_get_basic array_iter vp in
        let _ = dbus_message_iter_next array_iter in

        Some !@strp
    | _ -> None
  in

  let rec read_message l =
    match get_next_string () with
    | None -> l
    | Some s -> read_message (s :: l)
  in

  Ok (read_message [])

let get_mpris_busses connection =
  let+ busses = get_busses connection in
  Ok (List.filter (String.starts_with ~prefix:"org.mpris.MediaPlayer2") busses)

let mpris_call_method method_name connection bus =
  let open C.Type in
  let open C.Functions in
  let message =
    dbus_message_new_method_call bus "/org/mpris/MediaPlayer2"
      "org.mpris.MediaPlayer2.Player" method_name
  in
  let _response =
    dbus_connection_send_with_reply_and_block connection message
      dbus_timeout_use_default None
  in
  ()

let mpris_call_method_all method_name connection =
  let+ busses = get_mpris_busses connection in
  List.iter (mpris_call_method method_name connection) busses;
  Ok ()

let pause = mpris_call_method_all "Pause"
let play = mpris_call_method_all "Play"
let play_pause = mpris_call_method_all "PlayPause"
let stop = mpris_call_method_all "Stop"
