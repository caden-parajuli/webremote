open Tyxml_html

val render : Tyxml.Html.doc -> string
val use_svg : uri -> Svg_types.spacestrings -> [> Html_types.svg ] elt
val key_button : Keyboard.key -> [> Html_types.button ] elt

val build_key_grid :
  (int * int * [< Html_types.div_content_fun > `Div ] elt) list_wrap ->
  [> Html_types.div ] elt

val basePage :
  title':uri ->
  ?headContent:Html_types.head_content_fun elt list ->
  content:[< Html_types.flow5 ] elt list ->
  unit ->
  [> Html_types.html ] elt
