val basePage :
  title':Tyxml_html.uri ->
  ?headContent:Html_types.head_content_fun Tyxml_html.elt list ->
  content:[< Html_types.flow5 ] Tyxml_html.elt list ->
  unit ->
  [> Html_types.html ] Tyxml_html.elt

val render : Tyxml.Html.doc -> string
