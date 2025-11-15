type app = {
  name : string;
  pretty_name : string;
  launch_command : string;
  icon_path : string option;
  default_workspace : int option;
}

val load_config : string option -> (app list, string) result
val launch_app : app -> Unix.process_status
val switch_to : app -> unit
