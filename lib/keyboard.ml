open Unix

let invalid = 0
let enter = 28
let up = 103
let left = 105
let right = 106
let down = 108
let back = 14
let media_pause = 162
let media_previous = 144
let media_next = 145
let media_stop = 164

type key =
  | Up
  | Left
  | Right
  | Down
  | Enter
  | Back
  | Invalid

let string_of_key key =
  match key with
  | Up -> "up"
  | Left -> "left"
  | Right -> "right"
  | Down -> "down"
  | Enter -> "enter"
  | Back -> "back"
  | Invalid -> "INVALID_KEY"

let int_of_key key =
  match key with
  | Up -> up
  | Left -> left
  | Right -> right
  | Down -> down
  | Enter -> enter
  | Back -> back
  | Invalid -> invalid

let key_of_string key =
  match key with
  | "up" -> Up
  | "left" -> Left
  | "right" -> Right
  | "down" -> Down
  | "enter" -> Enter
  | "back" -> Enter
  | _ -> Invalid

let display_key key = String.capitalize_ascii @@ string_of_key key

let press_key key =
  if key = Invalid then
    ()
  else
    print_endline @@ string_of_key key;
    let code = string_of_int @@ int_of_key key in
    let command = "ydotool key " ^ code ^ ":1 " ^ code ^ ":0" in
    let _ = open_process_out command in
    ()

