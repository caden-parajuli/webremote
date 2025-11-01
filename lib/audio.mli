type s

val init : unit -> s option
val close : s -> unit
val get_volume : s -> int option
val set_volume : s -> int -> int option
val raise_volume : s -> int -> int option
val lower_volume : s -> int -> int option

