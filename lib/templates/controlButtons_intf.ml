open Tyxml_html

module type Intf = sig
  val control_button :
    string ->
    [< Html_types.button_content_fun ] Tyxml_html.elt ->
    [> Html_types.button ] Tyxml_html.elt

  val key_button : Keyboard.key -> [> Html_types.button ] elt
  val keyboard_dialog : [> Html_types.dialog ] Tyxml_html.elt

  val build_control_grid :
    (int * int * [< Html_types.div_content_fun > `Div ] elt) list_wrap ->
    [> Html_types.div ] elt
end
