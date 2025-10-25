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

let render my_html = Format.asprintf "%a" (Tyxml.Html.pp ()) my_html
