open Webremote

let respond_debug message = Dream.respond ~status:`OK ~code:200 message

let to_manifest handler =
 fun req ->
  let%lwt message = handler req in
  let () =
    Dream.set_header message "Content-Type" "application/manifest+json"
  in
  Lwt.return message

let handle_req audio_state =
  let open Dream in
  router
    [
      get "/" (fun _ -> Pages.index |> Templates.render |> Dream.html);
      get "/favicon.ico" @@ from_filesystem "./public/icons" "favicon.ico";
      get "/service-worker.js" @@ from_filesystem "./public" "service-worker.js";
      get "/manifest.json" @@ to_manifest
      @@ from_filesystem "./public" "manifest.json";
      get "/echo/:word" (fun req -> Dream.html @@ param req "word");
      get "/command/test" (fun _ ->
          let _ = Sys.command "echo test > test.out" in
          Dream.html @@ Sys.getcwd ());
      get "/workspace/switch/:ws" (fun req ->
          match int_of_string_opt @@ param req "ws" with
          | Some ws ->
              WindowManager.switch_workspace ws;
              respond_debug "ran"
          | None ->
              Dream.respond ~code:400 ~status:`Bad_Request
                "argument must be a number");
      get "/kbd/press/:key" (fun req ->
          let open Keyboard in
          param req "key" |> key_of_string |> press_key;
          respond_debug "ran");
      get "/volume" (fun _ ->
          match Audio.get_volume audio_state with
          | None -> respond ~code:500 ~status:`Internal_Server_Error "-1"
          | Some volume -> respond @@ string_of_int volume);
      get "/volume/up" (fun _ ->
          match Audio.raise_volume audio_state 5 with
          | None -> respond ~code:500 ~status:`Internal_Server_Error "-1"
          | Some new_volume -> respond @@ string_of_int new_volume);
      get "/volume/down" (fun _ ->
          match Audio.lower_volume audio_state 5 with
          | None -> respond ~code:500 ~status:`Internal_Server_Error "-1"
          | Some new_volume -> respond @@ string_of_int new_volume);
      get "/static/**" @@ Dream.static "./public";
      get "/public/**" @@ Dream.static "./public";
    ]
