open Templates
open Tyxml_html

let headContent =
  [
    meta
      ~a:[ a_name "description"; a_content "Web-based remote for your HTPC" ]
      ();
    meta ~a:[ a_name "mobile-web-app-capable"; a_content "yes" ] ();
    meta ~a:[ a_name "apple-mobile-web-app-capable"; a_content "yes" ] ();
    meta ~a:[ a_name "apple-mobile-web-app-title"; a_content "WebRemote" ] ();
    meta
      ~a:[ a_name "apple-mobile-web-app-status-bar-style"; a_content "default" ]
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
        [ use_svg "/public/icons/pause_play.svg#pause-play" [ "media-svg" ] ];
      button
        ~a:
          [
            a_id "stop-button";
            a_title "Stop";
            a_class [ "btn"; "media-button" ];
          ]
        [ use_svg "/public/icons/stop.svg#stop" [ "media-svg" ] ];
    ]

let keyboard_button =
  let open Templates.ControlButtons in
  control_button "keyboard-button"
  @@ use_svg "/public/icons/keyboard.svg#symbol" []

let build_app_bar apps =
  let open Tyxml_html in
  let app_button (app : Apps.app) =
    button
      ~a:
        [
          a_id ("app-btn-" ^ app.name);
          a_class [ "btn"; "app-btn" ];
          a_user_data "app" app.name;
        ]
      [
        use_svg ("/public/icons/apps/" ^ app.name ^ ".svg#symbol") [ "app-svg" ];
      ]
  in
  div ~a:[ a_id "app-bar" ] @@ List.map app_button apps

let index apps =
  let title' = "WebRemote" in
  let content =
    let open Keyboard in
    let open Templates.ControlButtons in
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
      @@ [
           build_control_grid
             [
               (0, 1, key_button Up);
               (0, 2, key_button Back);
               (1, 0, key_button Left);
               (1, 1, key_button Enter);
               (1, 2, key_button Right);
               (2, 1, key_button Down);
               (2, 2, keyboard_button);
             ];
           build_app_bar apps;
         ];
      keyboard_dialog;
    ]
  in
  basePage ~title' ~headContent ~content ()
