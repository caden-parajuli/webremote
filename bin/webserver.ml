open Webremote

let respond_debug message = Dream.respond ~status:`OK ~code:200 message

let to_manifest handler =
 fun req ->
  let%lwt message = handler req in
  let () =
    Dream.set_header message "Content-Type" "application/manifest+json"
  in
  Lwt.return message

let get_volume_handler audio_state _req =
  match Audio.get_volume audio_state with
  | None -> Dream.respond ~code:500 ~status:`Internal_Server_Error "-1"
  | Some volume -> Dream.respond @@ string_of_int volume

let audio_set_handler audio_state audio_function amount =
  match audio_function audio_state amount with
  | None -> Dream.respond ~code:500 ~status:`Internal_Server_Error "-1"
  | Some new_volume -> Dream.respond @@ string_of_int new_volume

let result_handler f arg _req =
  match f arg with
  | Error e -> Dream.respond ~code:500 ~status:`Internal_Server_Error e
  | Ok _ -> Dream.respond @@ ""

let rec option_list_map f = function
  | [] -> []
  | x :: l -> (
      match f x with
      | None -> option_list_map f l
      | Some y -> y :: option_list_map f l)

let app_icon_handlers (apps : Apps.app list) =
  let open Filename in
  let open Apps in
  option_list_map
    (fun app ->
      match app.icon_path with
      | None -> None
      | Some path ->
          Some
            (Dream.get ("/public/icons/apps/" ^ app.name ^ ".svg")
            @@ Dream.from_filesystem (dirname path) (basename path)))
    apps

let handle_req audio_state mpris_connection apps =
  let open Dream in
  router
  (* Static *)
  @@ [
       get "/" (fun _ -> Pages.index apps |> Templates.render |> Dream.html);
       get "/favicon.ico" @@ from_filesystem "./public/icons" "favicon.ico";
       get "/service-worker.js"
       @@ from_filesystem "./public" "service-worker.js";
       get "/manifest.json" @@ to_manifest
       @@ from_filesystem "./public" "manifest.json";
       get "/static/**" @@ Dream.static "./public";
       get "/public/**" @@ Dream.static "./public";
     ]
  (* Apps *)
  @ app_icon_handlers apps
  @ [
      get "/app/open/:name" (fun req ->
          let open Apps in
          let name = param req "name" in
          match List.filter (fun a -> a.name = name) apps with
          | app :: _ ->
              switch_to app;
              respond_debug "switched"
          | [] -> respond_debug "switched");
    ]
  (* Window Manager *)
  @ [
      get "/workspace/switch/:ws" (fun req ->
          match int_of_string_opt @@ param req "ws" with
          | Some ws ->
              WindowManager.switch_workspace ws;
              respond_debug "ran"
          | None ->
              Dream.respond ~code:400 ~status:`Bad_Request
                "argument must be a number");
    ]
    (* Keyboard *)
  @ [
      get "/kbd/press/:key" (fun req ->
          let open Keyboard in
          param req "key" |> key_of_string |> press_key;
          respond_debug "ran");
      get "/kbd/down/:key" (fun req ->
          let open Keyboard in
          param req "key" |> key_of_string |> key_down;
          respond_debug "ran");
      get "/kbd/up/:key" (fun req ->
          let open Keyboard in
          param req "key" |> key_of_string |> key_up;
          respond_debug "ran");
      post "/kbd/type" (fun req ->
          let open Keyboard in
          let%lwt text = body req in
          type_string text;
          respond_debug "ran");
    ]
  (* Audio *)
  @ [
      (* Get *)
      get "/volume" @@ get_volume_handler audio_state;
      get "/volume/get" @@ get_volume_handler audio_state;
      (* Set *)
      get "/volume/set/:amount" (fun req ->
          match int_of_string_opt @@ param req "amount" with
          | None ->
              Dream.respond ~code:400 ~status:`Bad_Request
                "arument must be a number"
          | Some amount -> audio_set_handler audio_state Audio.set_volume amount);
      (* Raise *)
      get "/volume/up" (fun _ ->
          audio_set_handler audio_state Audio.raise_volume 5);
      get "/volume/up/:amount" (fun req ->
          match int_of_string_opt @@ param req "amount" with
          | None ->
              Dream.respond ~code:400 ~status:`Bad_Request
                "arument must be a number"
          | Some amount ->
              audio_set_handler audio_state Audio.raise_volume amount);
      (* Lower *)
      get "/volume/down" (fun _ ->
          audio_set_handler audio_state Audio.lower_volume 5);
      get "/volume/down/:amount" (fun req ->
          match int_of_string_opt @@ param req "amount" with
          | None ->
              Dream.respond ~code:400 ~status:`Bad_Request
                "arument must be a number"
          | Some amount ->
              audio_set_handler audio_state Audio.lower_volume amount);
    ]
  (* Mpris *)
  @ [
      get "/pause" @@ result_handler Mpris.pause mpris_connection;
      get "/play" @@ result_handler Mpris.play mpris_connection;
      get "/playpause" @@ result_handler Mpris.play_pause mpris_connection;
      get "/stop" @@ result_handler Mpris.stop mpris_connection;
    ]
