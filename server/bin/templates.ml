open Tyxml.Html

let basePage ~title' ?(headContent = []) ~content () =
  html
    (head (title @@ txt title')
    @@ List.append [ meta ~a:[ a_charset @@ uri_of_string "utf-8" ] () ]
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
