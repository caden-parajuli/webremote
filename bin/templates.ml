open Webremote
open Tyxml.Html

let basePage ~title' ?(headContent = []) ~content () =
  html
    (head (title @@ txt title')
    @@ List.append [ meta ~a:[ a_charset @@ uri_of_string "utf-8" ] () ]
    @@ List.append
         [
           meta
             ~a:
               [
                 a_name @@ uri_of_string "viewport";
                 a_content
                 @@ uri_of_string
                      "width=device-width, initial-scale=1.0, \
                       maximum-scale=1.0, user-scalable=no; \
                       target-densitydpi=device-dpi";
               ]
             ();
         ]
    @@ headContent)
    (body [ content ])

let keyButton key =
  let open Keyboard in
  match key with
  | Left | Right | Up | Down ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" @@ string_of_key key ]
        [ Arrow.use_svg ~classes:[ "arrow-svg"; "arrow-" ^ string_of_key key ] ]
  | Enter | Invalid ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" @@ string_of_key key ]
        [ b ~a:[ a_class [ "key-text" ] ] [ txt @@ display_key key ] ]

let index =
  let title' = "WebRemote" in
  let headContent =
    [
      link ~rel:[ `Stylesheet ] ~href:"static/index.css" ();
      script ~a:[ a_src @@ uri_of_string "static/index.js" ] (txt "");
      link ~rel:[ `Manifest ] ~href:"manifest.json" ();
    ]
  in
  let content =
    let open Keyboard in
    div
      ~a:[ a_class [ "bottom-content" ] ]
      [
        div
          ~a:[ a_class [ "key-buttons" ] ]
          [
            div ~a:[ a_class [ "button-row" ] ] [ keyButton Up ];
            div
              ~a:[ a_class [ "button-row" ] ]
              [ keyButton Left; keyButton Enter; keyButton Right ];
            div ~a:[ a_class [ "button-row" ] ] [ keyButton Down ];
          ];
      ]
  in
  basePage ~title' ~headContent ~content ()

let render my_html = Format.asprintf "%a" (Tyxml.Html.pp ()) my_html
