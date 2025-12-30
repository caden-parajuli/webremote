use maud::{Markup, html};

use crate::{
    keyboard::Key,
    templates::{
        base_page,
        control_buttons::{build_control_grid, key_button}, use_svg,
    },
};

const TITLE: &str = "WebRemote";
const DESCRIPTION: &str = "Web-based remote for your HTPC";

fn volume_control_bar() -> Markup {
    html! {
        .volume-bar {
            button #volume-down .btn.volume-btn {
                "-"
            }
            input #volume-slider .volume-slider type="range" min="0" max="100" step="1";
            button #volume-up .btn.volume-btn {
                "+"
            }
        {}
        }
    }
}

fn media_control_bar() -> Markup {
    html! {
        #media-control-bar {
            button #play-pause-button .btn.media-btn.media-button title="Pause/Play" {
                (use_svg("/public/icons/pause_play.svg#pause-play", &["media-svg"]))
            }
            button #stop-button .btn.media-btn.media-button title="Stop" {
                (use_svg("/public/icons/stop.svg#stop", &["media-svg"]))
            }
        }
    }
}

fn build_app_bar(apps: &[usize]) //-> Markup
{

}

pub async fn index() -> Markup {
    let head_content = html! {
        meta description=(DESCRIPTION);
        meta mobile-web-app-capable="yes";
        meta apple-mobile-web-app-capable="yes";
        meta apple-mobile-web-app-title=(TITLE);
        meta apple-mobile-web-app-status-bar-style="default";

        link rel="stylesheet" href="public/index.css";
        link rel="stylesheet" href="public/slider.css";
        //script src="static/index.js";

        link rel="manifest" href="manifest.json";

        // iOS Favicons
        link rel="apple-touch-icon" href="/public/icons/icon_x180.png" sizes="180x180";
        link rel="apple-touch-icon" href="/public/icons/icon_x192.png" sizes="192x192";
    };

    let content = html! {
        main {
            header {};
            div {
                #volume-level .volume-text {
                    "..."
                }
                (volume_control_bar());
                (media_control_bar());
            }
        }

        footer {
            (build_control_grid([
               (0, 1, key_button(Key::Up)),
               (0, 2, key_button(Key::Back)),
               (1, 0, key_button(Key::Left)),
               (1, 1, key_button(Key::Enter)),
               (1, 2, key_button(Key::Right)),
               (2, 1, key_button(Key::Down)),
               // (2, 2, keyboard_button),
             ]));
        }
    };

    base_page(TITLE, head_content, content)
}
