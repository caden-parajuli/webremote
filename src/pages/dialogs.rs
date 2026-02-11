use axum::extract::State;
use maud::{Markup, html};

use crate::{AppState, templates::modal::{modal, modal_cancel, modal_ok}};

pub async fn keyboard_dialog(State(_state): State<AppState>) -> Markup {
    modal(
        "keyboard-modal",
        html! {
            form #keyboard-form method="dialog" {
                label #to-type-label for="to-type" {
                    "Type:";
                }
                br {};
                input #to-type name="to-type" input-type="text" value="" placeholder="message" autofocus {
                }
                #keyboard-ok-cancel .ok-cancel {
                    (modal_cancel("keyboard-cancel"));
                    (modal_ok("keyboard-ok"));
                }
            }
        },
    )
}
