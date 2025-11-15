module IntMap = Map.Make (Int)

let workspaces =
  IntMap.of_list
    [
      (1, Some "kodi");
      (2, None);
      (3, None);
      (4, None);
      (5, None);
      (6, None);
      (7, None);
      (8, None);
      (9, None);
      (10, None);
    ]

type window_manager =
  | Sway
  | Hyprland

let window_manager_of_string = function
  | "sway" -> Some Sway
  | "hyprland" -> Some Hyprland
  | _ -> None

let home = ref 1
let current = ref 1
let wm = ref Sway

let sway_exec command =
  close_out_noerr @@ Unix.open_process_out @@ "swaymsg -t command -- ''"
  ^ command

let hypr_exec command =
  close_out_noerr @@ Unix.open_process_out @@ "hyprctl dispatch " ^ command

let is_workspace num = Option.is_some @@ IntMap.find_opt num workspaces

let is_empty num =
  match IntMap.find_opt num workspaces with
  | None -> false
  | Some None -> true
  | Some _ -> false

let switch_workspace name =
  match !wm with
  | Sway ->
      if is_workspace name then
        sway_exec @@ "workspace " ^ string_of_int name
      else
        print_endline "Invalid workspace"
  | Hyprland ->
      if is_workspace name then
        hypr_exec @@ "workspace " ^ string_of_int name
      else
        ()
