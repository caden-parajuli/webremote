type connection

val connect : unit -> connection option
val get_busses : connection -> (string list, string) result
val get_mpris_busses : connection -> (string list, string) result
val pause : connection -> (unit, string) result
val play : connection -> (unit, string) result
val play_pause : connection -> (unit, string) result
val stop : connection -> (unit, string) result
