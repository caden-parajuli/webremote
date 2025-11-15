open Unix

let invalid = 0
let enter = 28
let up = 103
let left = 105
let right = 106
let down = 108
let back = 1 (* esc *)

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
  | "back" -> Back
  | _ -> Invalid

let display_key key = String.capitalize_ascii @@ string_of_key key

let key_down key =
  if key = Invalid then
    prerr_endline "Tried to press down invalid key"
  else
    let code = string_of_int @@ int_of_key key in
    let command = "ydotool key " ^ code ^ ":1" in
    close_out_noerr @@ open_process_out command;
    ()

let key_up key =
  if key = Invalid then
    prerr_endline "Tried to lift invalid key"
  else
    let code = string_of_int @@ int_of_key key in
    let command = "ydotool key " ^ code ^ ":0" in
    close_out_noerr @@ open_process_out command;
    ()

let press_key key =
  if key = Invalid then
    prerr_endline "Tried to press invalid key"
  else
    let code = string_of_int @@ int_of_key key in
    let command = "ydotool key " ^ code ^ ":1 " ^ code ^ ":0" in
    close_out_noerr @@ open_process_out command;
    ()

let type_string text =
  let command = "ydotool type '" ^ text ^ "'" in
  close_out_noerr @@ open_process_out command;
  ()
