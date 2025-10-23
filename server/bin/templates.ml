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
                 @@ uri_of_string "width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no; target-densitydpi=device-dpi";
               ]
             ();
         ]
    @@ headContent)
    (body [ content ])

let keyButton key =
  match key with
  | "left" | "right" | "up" | "down" ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" key ]
        [ i ~a:[ a_class [ "arrow"; "arrow-" ^ key ] ] [] ]
  | _ ->
      button ~a:[ a_class [ "key-button" ]; a_user_data "key" key ] [ txt key ]

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
    div
      [
        div ~a:[ a_class [ "button-row" ] ] [ keyButton "up" ];
        div
          ~a:[ a_class [ "button-row" ] ]
          [ keyButton "left"; keyButton "enter"; keyButton "right" ];
        div ~a:[ a_class [ "button-row" ] ] [ keyButton "down" ];
      ]
  in
  basePage ~title' ~headContent ~content ()

let render my_html = Format.asprintf "%a" (Tyxml.Html.pp ()) my_html
