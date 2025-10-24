open Unix

let invalid = 0
let enter = 28
let up = 103
let left = 105
let right = 106
let down = 108

type key =
  | Up
  | Left
  | Right
  | Down
  | Enter
  | Invalid

let string_of_key key =
  match key with
  | Up -> "up"
  | Left -> "left"
  | Right -> "right"
  | Down -> "down"
  | Enter -> "enter"
  | Invalid -> "INVALID_KEY"

let key_of_string key =
  match key with
  | "up" -> Up
  | "left" -> Left
  | "right" -> Right
  | "down" -> Down
  | "enter" -> Enter
  | _ -> Invalid

let display_key key = String.capitalize_ascii @@ string_of_key key

let press_key keycode =
  if keycode = invalid then
    ()
  else
    let strcode = string_of_int keycode in
    let command = "ydotool key " ^ strcode ^ ":1 " ^ strcode ^ ":0" in
    let _ = open_process_out command in
    ()

let getcode key =
  match key with
  | Right -> right
  | Left -> left
  | Up -> up
  | Down -> down
  | Enter -> enter
  | _ -> invalid
