pub mod control_buttons;
pub mod modal;

use maud::{DOCTYPE, Markup, PreEscaped, html};

pub fn use_svg(href: &str, classes: &[&str]) -> Markup {
    let joined = classes.join(" ");

    PreEscaped(format!(
        "<svg \
          xmlns=\"http://www.w3.org/2000/svg\" \
          xmlns:xlink=\"http://www.w3.org/1999/xlink\" \
          viewBox=\"0 0 16 16\" \
          class=\"svg {joined}\">\
            <use href=\"{href}\"></use>\
        </svg>"
    ))
}

pub fn base_page(title: &str, head_content: Markup, content: Markup) -> Markup {
    let viewport = "width=device-width, initial-scale=1.0, maximum-scale=1.0, \
     interactive-widget=resizes-content, user-scalable=no, \
     target-densitydpi=device-dpi";

    html! {
        (DOCTYPE)
        html {
            head {
                title { (title) };

                meta charset="utf-8";
                meta name="viewport" content=(viewport);

                link rel="icon" href="/favicon.ico" mime-type="image/x-icon";
                link rel="icon" href="/public/icons/icon_x16.png" size="16x16" mime-type="image/png";
                link rel="icon" href="/public/icons/icon_x32.png" size="32x32" mime-type="image/png";
                link rel="icon" href="/public/icons/icon_x48.png" size="48x48" mime-type="image/png";

                (head_content)
            }
            body {
                (content)
            }
        }
    }
}
