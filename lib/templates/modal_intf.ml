open Tyxml_html

module type Intf = sig
  val modal_ok :
    a:[< Html_types.button_attrib > `Class `Id `Text_Value ] attrib list_wrap ->
    uri ->
    [> Html_types.button ] elt

  val modal_cancel : string -> [> Html_types.button ] elt

  val modal :
    string ->
    [< Html_types.dialog_content_fun ] elt list_wrap ->
    [> Html_types.dialog ] elt
end
