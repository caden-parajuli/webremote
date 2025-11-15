type window_manager =
  | Sway
  | Hyprland

val home : int ref
val current : int ref
val wm : window_manager ref

val window_manager_of_string : string -> window_manager option
val switch_workspace : int -> unit
