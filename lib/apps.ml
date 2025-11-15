module WebRemote_id = struct
  let qualifier = "com"
  let organization = "cadenp"
  let application = "webremote"
end

module Dirs = Directories.Project_dirs (WebRemote_id)

type app = {
  (* Used in code *)
  name : string;
  (* Used to display to user *)
  pretty_name : string;
  launch_command : string;
  (* Not needed for builtin apps *)
  icon_path : string option;
  default_workspace : int option;
}

let ( let+ ) = Result.bind
let config_name = "config.json5"

let default_config =
  {|{
  window_manager: "sway",
  apps: [
    {
      name: "kodi",
      pretty_name: "Kodi",
      launch_command: "kodi",
      default_workspace: 1
    },
    {
      name: "youtube",
      pretty_name: "YouTube",
      launch_command: "VacuumTube",
      default_workspace: 2
    }
  ]
}|}

(** brain-dead implementation *)
let rec map_or_first_err f l =
  match l with
  | [] -> Ok []
  | x :: xs -> (
      match f x with
      | Error e -> Error e
      | Ok fx -> (
          match map_or_first_err f xs with
          | Error e -> Error e
          | Ok l -> Ok (fx :: l)))

let get_config_path path =
  match path with
  | Some p -> Some p
  | None -> (
      match Sys.getenv_opt "WEBREMOTE_CONFIG" with
      | Some p -> Some p
      | None -> (
          match Dirs.config_dir with
          | Some d -> Some (Fpath.to_string @@ Fpath.add_seg d config_name)
          | None -> None))

let parse_app_config (a : Yojson_five.Safe.t) =
  let name = ref None in
  let pretty_name = ref None in
  let icon_path = ref None in
  let launch_command = ref None in
  let default_workspace = ref None in
  let+ () =
    match a with
    | `Assoc props ->
        Ok
          (List.iter
             (function
               | "name", `String s -> name := Some s
               | "pretty_name", `String s -> pretty_name := Some s
               | "icon_path", `String s -> icon_path := Some s
               | "launch_command", `String s -> launch_command := Some s
               | "default_workspace", `Int i -> default_workspace := Some i
               | _ -> ())
             props)
    | _ -> Error "Configuration is not in the proper format"
  in
  let+ name = Option.to_result !name ~none:"Required field \"name\" is empty" in
  let pretty_name = Option.value !pretty_name ~default:name in
  let+ launch_command =
    Option.to_result !launch_command
      ~none:"Required field \"launch_command\" is empty"
  in
  Ok
    {
      name;
      pretty_name;
      launch_command;
      icon_path = !icon_path;
      default_workspace = !default_workspace;
    }

let rec mkdir_p path permissions =
  let up = Filename.dirname path in
  if path <> "/" then (
    mkdir_p up permissions;
    if not (Sys.file_exists path && Sys.is_directory path) then
      Sys.mkdir path permissions)

let load_config (config_path : string option) =
  let+ config_path =
    Option.to_result ~none:"Config path not specified"
    @@ get_config_path config_path
  in

  (* Create default config file if it doesn't exist *)
  if not (Sys.file_exists config_path && Sys.is_regular_file config_path) then (
    mkdir_p (Filename.dirname config_path) 0o755;
    let oc = open_out config_path in
    try
      output_string oc default_config;
      flush oc;
      close_out oc
    with e ->
      close_out_noerr oc;
      raise e);

  let+ json = Yojson_five.Safe.from_file config_path in
  match json with
  | `Assoc a -> (
      match List.find_opt (fun (k, _) -> k = "window_manager") a with
      | Some (_, `String s) -> (
          (match WindowManager.window_manager_of_string s with
          | Some wm -> WindowManager.wm := wm
          | None -> ());
          match List.find_opt (fun (k, _) -> k = "apps") a with
          | Some (_, `List l) -> map_or_first_err parse_app_config l
          | _ -> Error "Configuration format error: apps list missing or wrong type")
      | _ -> Error "Configuration format error: window_manager missing or wrong type")
  | _ -> Error "Configuration format error: not association list"

let launch_app (app : app) = Unix.system app.launch_command

let switch_to (app : app) =
  (* todo: check if the app exists and launch if not *)
  match app.default_workspace with
  | Some ws -> WindowManager.switch_workspace ws
  | None -> ()
