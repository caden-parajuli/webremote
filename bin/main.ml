let usage_msg = "usage: webremote [--port <port>] [--interface <interface>]"
let handle_anon _arg = ()
let port = ref 8080
let interface = ref "0.0.0.0"
let config = ref None

let speclist =
  [
    ("--port", Arg.Set_int port, "The port to listen on");
    ("--interface", Arg.Set_string interface, "The interface to listen on");
    ( "--config",
      Arg.String (fun s -> config := Some s),
      "Configuration file path" );
  ]

let die message =
  prerr_endline message;
  exit 1

let main () =
  let open Dream in
  let ( let+ ) = Result.bind in
  let ( +!> ) = fun a b -> Option.to_result a ~none:b in

  let () = Arg.parse speclist handle_anon usage_msg in
  let+ apps = Apps.load_config !config in

  let+ audio_state = Audio.init () +!> "Could not connect to PulseAudio" in
  let+ mpris_connection =
    Webremote.Mpris.connect () +!> "Could not connet to DBus"
  in

  let () =
    Webserver.handle_req audio_state mpris_connection apps
    |> logger
    |> run ~interface:!interface ~port:!port
  in
  Ok ()

let () =
  match main () with
  | Ok () -> ()
  | Error e -> die e
