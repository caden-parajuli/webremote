let usage_msg = "usage: webremote [--port <port>] [--interface <interface>]"
let handle_anon _arg = ()
let port = ref 8080
let interface = ref "0.0.0.0"

let speclist =
  [
    ("--port", Arg.Set_int port, "The port to listen on");
    ("--interface", Arg.Set_string interface, "The interface to listen on");
  ]

let die message =
  prerr_endline message;
  exit 1

let () =
let open Dream in
let () = Arg.parse speclist handle_anon usage_msg in

match Audio.init () with
| None -> die "Could not connect to PulseAudio"
| Some audio_state ->

  match Webremote.Mpris.connect () with
  | None -> die "Could not connect to DBus"
  | Some mpris_connection -> 
    Webserver.handle_req audio_state mpris_connection
    |> logger
    |> run ~interface:!interface ~port:!port
