open Tyxml_html

let modal_ok ~a id =
  button
    ~a:
      ([
         a_id id;
         a_class [ "btn"; "modal-btn"; "ok-btn" ];
         a_text_value "default";
       ]
      @ a)
    [ b [ txt "Ok" ] ]

let modal_cancel id =
  button
    ~a:
      [
        a_id id;
        a_class [ "btn"; "modal-btn"; "cancel-btn" ];
        a_text_value "";
        Unsafe.string_attrib "formmethod" "dialog";
      ]
    [ b [ txt "Cancel" ] ]

let modal id els =
  dialog ~a:[ a_id id; a_class [ "modal" ]; a_role [ "dialog" ] ] els
