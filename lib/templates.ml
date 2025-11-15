open Tyxml.Html

let render my_html = Format.asprintf "%a" (Tyxml.Html.pp ()) my_html

let use_svg href classes =
  let open Tyxml_svg in
  Tyxml_html.svg
    ~a:[ a_viewBox (0.0, 0.0, 16.0, 16.0); a_class classes ]
    [ use ~a:[ a_href href ] [] ]

let use_arrow_svg key =
  use_svg "public/icons/arrow.svg#arrow-symbol"
    [ "arrow-svg"; "arrow-" ^ Keyboard.string_of_key key ]

let control_button elt id =
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

let build_key_grid grid =
  let button_spacer = Tyxml_html.(div ~a:[ a_class [ "control-btn-spacer" ] ] []) in
  let full_grid = Array.make_matrix 3 3 button_spacer in

  let set (y, x, elt) = full_grid.(y).(x) <- elt in
  let () = List.iter set grid in

  let open Tyxml_html in
  div ~a:[ a_class [ "key-buttons" ] ]
  @@ Array.to_list
  @@ Array.map
       (fun row -> div ~a:[ a_class [ "button-row" ] ] @@ Array.to_list row)
       full_grid

let basePage ~title' ?(headContent = []) ~content () =
  let viewport =
    "width=device-width, initial-scale=1.0, maximum-scale=1.0, \
     interactive-widget=resizes-content, user-scalable=no, \
     target-densitydpi=device-dpi"
  in
  let iconLink path size =
    link ~rel:[ `Icon ] ~href:path
      ~a:[ a_sizes @@ Some [ (size, size) ]; a_mime_type "image/png" ]
      ()
  in
  let templateHead =
    [
      meta ~a:[ a_charset @@ "utf-8" ] ();
      meta ~a:[ a_name "viewport"; a_content viewport ] ();
      link ~rel:[ `Icon ] ~href:"/favicon.ico"
        ~a:[ a_mime_type "image/x-icon" ]
        ();
      iconLink "/public/icons/icon_x16.png" 16;
      iconLink "/public/icons/icon_x32.png" 32;
      iconLink "/public/icons/icon_x48.png" 48;
    ]
  in
  html (head (title @@ txt title') @@ List.append templateHead @@ headContent)
  @@ body content
