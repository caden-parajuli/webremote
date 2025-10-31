open Unix

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
val display_key : key -> string
val press_key : key -> unit
val getcode : key -> int
