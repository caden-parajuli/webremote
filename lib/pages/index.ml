open Templates
(* open Tyxml_html *)

let use_arrow_svg ~classes =
  let open Tyxml_svg in
  Tyxml_html.svg
    ~a:[ a_viewBox (0.0, 0.0, 16.0, 16.0); a_class classes ]
    [ use ~a:[ a_href "public/icons/arrow.svg#arrow-symbol" ] [] ]

let keyButton key =
  let open Tyxml_html in
  let open Keyboard in
  match key with
  | Left | Right | Up | Down ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" @@ string_of_key key ]
        [ use_arrow_svg ~classes:[ "arrow-svg"; "arrow-" ^ string_of_key key ] ]
  | Enter | Back | Invalid ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" @@ string_of_key key ]
        [ b ~a:[ a_class [ "key-text" ] ] [ txt @@ display_key key ] ]

let build_grid (grid : (int * int * Keyboard.key) list) =
  let button_spacer = Tyxml_html.(div ~a:[ a_class [ "button-spacer" ] ] []) in
  let full_grid = Array.make_matrix 3 3 button_spacer in

  let set (y, x, key) = full_grid.(y).(x) <- keyButton key in
  let () = List.iter set grid in

  let open Tyxml_html in
  div ~a:[ a_class [ "key-buttons" ] ]
  @@ Array.to_list
  @@ Array.map
       (fun row -> div ~a:[ a_class [ "button-row" ] ] @@ Array.to_list row)
       full_grid

let index =
  let open Tyxml_html in
  let title' = "WebRemote" in
  let headContent =
    [
      meta
        ~a:[ a_name "description"; a_content "Web-based remote for your HTPC" ]
        ();
      meta ~a:[ a_name "mobile-web-app-capable"; a_content "yes" ] ();
      meta ~a:[ a_name "apple-mobile-web-app-capable"; a_content "yes" ] ();
      meta ~a:[ a_name "apple-mobile-web-app-title"; a_content "WebRemote" ] ();
      meta
        ~a:
          [
            a_name "apple-mobile-web-app-status-bar-style"; a_content "default";
          ]
        ();
      link ~rel:[ `Stylesheet ] ~href:"static/index.css" ();
      script ~a:[ a_src @@ uri_of_string "static/index.js" ] (txt "");
      link ~rel:[ `Manifest ] ~href:"manifest.json" ();
      (* Favicons *)
      link
        ~rel:[ `Other "apple-touch-icon" ]
        ~href:"/public/icons/icon_x180.png"
        ~a:[ a_sizes @@ Some [ (180, 180) ] ]
        ();
      link
        ~rel:[ `Other "apple-touch-icon" ]
        ~href:"/public/icons/icon_x192.png"
        ~a:[ a_sizes @@ Some [ (192, 192) ] ]
        ();
    ]
  in
  let content =
    let open Keyboard in
    [
      main [ div [] ];
      footer
        [
          build_grid [
            0, 1, Up;
            0, 2, Up;
            1, 0, Left;
            1, 1, Enter;
            1, 2, Right;
            2, 1, Down;
          ]
          (* div *)
          (*   ~a:[ a_class [ "key-buttons" ] ] *)
          (*   [ *)
          (*     div *)
          (*       ~a:[ a_class [ "button-row" ] ] *)
          (*       [ *)
          (*         div ~a:[ a_class [ "button-spacer" ] ] []; *)
          (*         keyButton Up; *)
          (*         keyButton Back; *)
          (*       ]; *)
          (*     div *)
          (*       ~a:[ a_class [ "button-row" ] ] *)
          (*       [ keyButton Left; keyButton Enter; keyButton Right ]; *)
          (*     div ~a:[ a_class [ "button-row" ] ] [ keyButton Down ]; *)
          (*   ]; *)
        ];
    ]
  in
  basePage ~title' ~headContent ~content ()
