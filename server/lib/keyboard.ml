open Unix

let invalid = 0
let enter = 28
let up = 103
let left = 105
let right = 106
let down = 108

let press_key keycode =
  if keycode = invalid then
    ()
  else
    let strcode = string_of_int keycode in
    let command =
      "ydotool key " ^ strcode ^ ":1 "
      ^ strcode ^ ":0"
    in
    let _ = open_process_out command in
    ()

let getcode keyname = 
  match keyname with
  | "right" -> right
  | "left" -> left
  | "up" -> up
  | "down" -> down
  | "enter" -> enter
  | _ -> invalid
