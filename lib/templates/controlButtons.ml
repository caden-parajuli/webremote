open Common

let use_arrow_svg key =
  use_svg "public/icons/arrow.svg#arrow-symbol"
    [ "arrow-svg"; "arrow-" ^ Keyboard.string_of_key key ]

let control_button id elt =
  let open Tyxml_html in
  button ~a:[ a_class [ "btn"; "control-button" ]; a_id id ] [ elt ]

let key_button key =
  let open Tyxml_html in
  let open Keyboard in
  match key with
  | Left | Right | Up | Down ->
      button
        ~a:
          [
            a_class [ "btn"; "control-button"; "key-button" ];
            a_user_data "key" @@ string_of_key key;
          ]
        [ use_arrow_svg key ]
  | Enter | Back | Invalid ->
      button
        ~a:
          [
            a_class [ "btn"; "control-button"; "key-button" ];
            a_user_data "key" @@ string_of_key key;
          ]
        [ b ~a:[ a_class [ "key-text" ] ] [ txt @@ display_key key ] ]

let build_control_grid grid =
  let button_spacer =
    Tyxml_html.(div ~a:[ a_class [ "control-btn-spacer" ] ] [])
  in
  let full_grid = Array.make_matrix 3 3 button_spacer in

  let set (y, x, elt) = full_grid.(y).(x) <- elt in
  let () = List.iter set grid in

  let open Tyxml_html in
  div ~a:[ a_class [ "key-buttons" ] ]
  @@ Array.to_list
  @@ Array.map
       (fun row -> div ~a:[ a_class [ "button-row" ] ] @@ Array.to_list row)
       full_grid

let keyboard_dialog =
  let open Tyxml_html in
  let open Modal in
  modal "keyboard-modal"
    [
      form
        ~a:[ a_id "keyboard-form"; Unsafe.string_attrib "method" "dialog" ]
        [
          label
            ~a:[ a_id "to-type-label"; a_label_for "to-type" ]
            [ txt "Type:" ];
          br ();
          input
            ~a:
              [
                a_id "to-type";
                a_name "to-type";
                a_input_type `Text;
                a_value "";
                a_placeholder "message";
                a_autofocus ();
              ]
            ();
          div
            ~a:[ a_id @@ "keyboard-ok-cancel"; a_class [ "ok-cancel" ] ]
            [ modal_cancel "keyboard-cancel"; modal_ok ~a:[] "keyboard-ok" ];
        ];
    ]
