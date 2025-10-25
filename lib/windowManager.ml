(* open Sys *)
open Unix
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

type window_manager = 
  | Sway
  | Hyprland

let home = ref "1"
let current = ref "1"
let wm = ref Sway

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
  | Sway ->
      if is_workspace name then
        sway_command @@ "workspace " ^ name
      else
        print_endline "Invalid workspace"
  | Hyprland ->
      if is_workspace name then
        hypr_command @@ "workspace " ^ name
      else
        ()

