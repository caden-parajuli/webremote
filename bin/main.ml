let usage_msg = "usage: webremote [--port <port>] [--interface <interface>]"
let handle_anon _arg = ()
let port = ref 8080
let interface = ref "0.0.0.0"

let speclist = [
  ("--port", Arg.Set_int port, "The port to listen on");
  ("--interface", Arg.Set_string interface, "The interface to listen on");
]


let () =
  let open Dream in
  let () = Arg.parse speclist handle_anon usage_msg in
  Webserver.handle_req |> logger |> run ~interface:!interface ~port:!port
