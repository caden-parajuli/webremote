open Tyxml_html

module ControlButtons : ControlButtons_intf.Intf
module Modal : Modal_intf.Intf

val render : Tyxml.Html.doc -> string
val use_svg : uri -> Svg_types.spacestrings -> [> Html_types.svg ] elt

val basePage :
  title':uri ->
  ?headContent:Html_types.head_content_fun elt list ->
  content:[< Html_types.flow5 ] elt list ->
  unit ->
  [> Html_types.html ] elt
