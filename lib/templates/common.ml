let use_svg href classes =
  let open Tyxml_svg in
  Tyxml_html.svg
    ~a:[ a_viewBox (0.0, 0.0, 16.0, 16.0); a_class ("svg" :: classes) ]
    [ use ~a:[ a_href href ] [] ]
