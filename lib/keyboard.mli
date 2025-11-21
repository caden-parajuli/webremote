type key =
  | Up
  | Left
  | Right
  | Down
  | Enter
  | Back
  | Invalid

val string_of_key : key -> string
val key_of_string : string -> key
val int_of_key : key -> int
val display_key : key -> string
val press_key : key -> unit
val key_down : key -> unit
val key_up : key -> unit
val type_string : string -> unit
