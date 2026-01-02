use maud::{html, Markup};

pub fn modal_ok(id: &str) -> Markup {
    html! {
        button #(id) .btn.modal-btn.ok-btn value="default" {
            b { "Ok"; }
        }
    }
}

pub fn modal_cancel(id: &str) -> Markup {
    html! {
        button #(id) .btn.modal-btn.cancel-btn value="" formmethod="dialog" {
            b { "Cancel"; }
        }
    }
}

pub fn modal(id: &str, content: Markup) -> Markup {
    html! {
        dialog #(id) .modal role="dialog" {
            (content);
        }
    }
}
