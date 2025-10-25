open Webremote
open Tyxml.Html

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

      link ~rel:[ `Icon ] ~href:"/favicon.ico" ~a:[ a_mime_type "image/x-icon" ] ();
      iconLink "/public/icons/icon_x16.png" 16;
      iconLink "/public/icons/icon_x32.png" 32;
      iconLink "/public/icons/icon_x48.png" 48;
    ]
  in
  html (head (title @@ txt title') @@ List.append templateHead @@ headContent)
  @@ body content

let keyButton key =
  let open Keyboard in
  match key with
  | Left | Right | Up | Down ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" @@ string_of_key key ]
        [ Arrow.use_svg ~classes:[ "arrow-svg"; "arrow-" ^ string_of_key key ] ]
  | Enter | Back | Invalid ->
      button
        ~a:[ a_class [ "key-button" ]; a_user_data "key" @@ string_of_key key ]
        [ b ~a:[ a_class [ "key-text" ] ] [ txt @@ display_key key ] ]

let index =
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
          div
            ~a:[ a_class [ "key-buttons" ] ]
            [
              div
                ~a:[ a_class [ "button-row" ] ]
                [
                  div ~a:[ a_class [ "button-spacer" ] ] [];
                  keyButton Up;
                  keyButton Back;
                ];
              div
                ~a:[ a_class [ "button-row" ] ]
                [ keyButton Left; keyButton Enter; keyButton Right ];
              div ~a:[ a_class [ "button-row" ] ] [ keyButton Down ];
            ];
        ];
    ]
  in
  basePage ~title' ~headContent ~content ()

let render my_html = Format.asprintf "%a" (Tyxml.Html.pp ()) my_html
