use maud::{Markup, html};

use crate::{
    keyboard::Key,
    templates::{
        modal::{modal, modal_cancel, modal_ok},
        use_svg,
    },
};

pub fn use_arrow_svg(key: Key) -> Markup {
    let mut keyclass = key.to_string();
    keyclass.insert_str(0, "arrow-");

    use_svg(
        "public/icons/arrow.svg#arrow-symbol",
        &["arrow-svg", &keyclass],
    )
}

pub fn control_button(id: &str, element: Markup) -> Markup {
    html! {
        button #(id) .btn.control-button {
            (element);
        }
    }
}

pub fn key_button(key: Key) -> Markup {
    let content = match key {
        Key::Left | Key::Right | Key::Up | Key::Down => use_arrow_svg(key),
        Key::Enter | Key::Back => html! {
            b .key-text {
                (key.display())
            }
        },
    };

    html! {
        button .btn.control-button.key-button data-key=(key.to_string()) {
            (content);
        }
    }
}

pub fn build_control_grid<T>(grid: T) -> Markup
where
    T: IntoIterator<Item = (usize, usize, Markup)>,
{
    let button_spacer = html! {
        .control-btn-spacer {}
    };

    let mut full_grid: [[Markup; 3]; 3] = core::array::repeat(core::array::repeat(button_spacer));
    for (y, x, elt) in grid {
        full_grid[y][x] = elt;
    }

    html! {
        .key-buttons {
            @for row in &full_grid {
                .button-row {
                    @for button in row {
                        (button);
                    }
                }
            }
        }
    }
}

pub fn keyboard_dialog() -> Markup {
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
