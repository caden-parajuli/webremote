open Unix
open Map
open Webremote
module StringMap = Map.Make (String)

let workspaces =
  StringMap.of_list
    [
      ("1", Some "kodi");
      ("2", None);
      ("3", None);
      ("4", None);
      ("5", None);
      ("6", None);
      ("7", None);
      ("8", None);
      ("9", None);
      ("10", None);
    ]

let home = ref "1"
let current = ref "1"
let wm = ref "sway"

let die msg =
  prerr_endline msg;
  exit 1

let sway_command command =
  let _ = open_process_out @@ "swaymsg -t command -- ''" ^ command in
  ()

let hypr_command command =
  let _ = open_process_out @@ "hyprctl dispatch " ^ command in
  ()

let is_workspace name = Option.is_some @@ StringMap.find_opt name workspaces

let switch_workspace name =
  match !wm with
  | "sway" ->
      if is_workspace name then
        sway_command @@ "workspace " ^ name
      else
        print_endline "Invalid workspace"
  | "hyprland" ->
      if is_workspace name then
        hypr_command @@ "workspace " ^ name
      else
        ()
  | _ -> die "Window manager not set!"

let do_debug _ = Dream.respond ~status:`OK ~code:200 "ran"

let to_manifest handler =
  fun req -> 
    let%lwt message = handler req in
    let () = Dream.set_header message "Content-Type" "application/manifest+json" in
    Lwt.return message

let handle_req =
  let open Dream in
  router
    [
      get "/" (fun _ ->
        Templates.index
          |> Templates.render
          |> Dream.html
      );
      get "/service-worker.js" @@ from_filesystem "./public" "service-worker.js";
      get "/manifest.json" @@ to_manifest @@ from_filesystem "./public" "manifest.json";
      get "/echo/:word" (fun req -> Dream.html @@ param req "word");
      get "/command/test" (fun _ ->
          let _ = Sys.command "echo test > test.out" in
          Dream.html @@ Sys.getcwd ());
      get "/workspace/switch/:ws" (fun req ->
          do_debug @@ switch_workspace @@ param req "ws");
      get "/kbd/press/:key" (fun req ->
          let open Keyboard in
          param req "key" |> getcode |> press_key |> do_debug);
      get "/static/**" @@ Dream.static "./public";
      get "/public/**" @@ Dream.static "./public";
    ]

let () =
  let open Dream in
  handle_req |> logger |> run ~interface:"0.0.0.0" ~port:8080
