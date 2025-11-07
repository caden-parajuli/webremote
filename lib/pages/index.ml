open Templates

let use_svg href classes =
  let open Tyxml_svg in
  Tyxml_html.svg
    ~a:[ a_viewBox (0.0, 0.0, 16.0, 16.0); a_class classes ]
    [ use ~a:[ a_href href ] [] ]

let use_arrow_svg key =
  use_svg "public/icons/arrow.svg#arrow-symbol"
    [ "arrow-svg"; "arrow-" ^ Keyboard.string_of_key key ]

let keyButton key =
  let open Tyxml_html in
  let open Keyboard in
  match key with
  | Left | Right | Up | Down ->
      button
        ~a:
          [
            a_class [ "btn"; "key-button" ];
            a_user_data "key" @@ string_of_key key;
          ]
        [ use_arrow_svg key ]
  | Enter | Back | Invalid | MediaPause | MediaStop | MediaPrevious | MediaNext
    ->
      button
        ~a:
          [
            a_class [ "btn"; "key-button" ];
            a_user_data "key" @@ string_of_key key;
          ]
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
      link ~rel:[ `Stylesheet ] ~href:"public/index.css" ();
      link ~rel:[ `Stylesheet ] ~href:"public/slider.css" ();
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
  let volume_control_bar =
    div
      ~a:[ a_class [ "volume-bar" ] ]
      [
        button
          ~a:[ a_id "volume-down"; a_class [ "btn"; "volume-btn" ] ]
          [ txt "-" ];
        input
          ~a:
            [
              a_input_type `Range;
              a_input_min (`Number 0);
              a_input_max (`Number 100);
              a_step (Some 1.0);
              a_id "volume-slider";
              a_class [ "volume-slider" ];
            ]
          ();
        button
          ~a:[ a_id "volume-up"; a_class [ "btn"; "volume-btn" ] ]
          [ txt "+" ];
      ]
  in
  let media_control_bar =
    div
      ~a:[ a_id "media-control-bar" ]
      [
        button
          ~a:
            [
              a_id "play-pause-button";
              a_title "Pause/Play";
              a_class [ "btn"; "media-button" ];
            ]
          [
            use_svg "/public/icons/pause_play.svg#pause-play"
              [ "svg"; "media-svg" ];
          ];
        button
          ~a:
            [
              a_id "stop-button";
              a_title "Stop";
              a_class [ "btn"; "media-button" ];
            ]
          [ use_svg "/public/icons/stop.svg#stop" [ "svg"; "media-svg" ] ];
      ]
  in

  let content =
    let open Keyboard in
    [
      main
        [
          header [];
          div
            [
              (* Volume level (percentage) label *)
              div
                ~a:[ a_id "volume-level"; a_class [ "volume-text" ] ]
                [ txt "0" ];
              volume_control_bar;
              media_control_bar;
            ];
        ];
      footer
        [
          build_grid
            [
              (0, 1, Up);
              (0, 2, Back);
              (1, 0, Left);
              (1, 1, Enter);
              (1, 2, Right);
              (2, 1, Down);
            ];
        ];
    ]
  in
  basePage ~title' ~headContent ~content ()
