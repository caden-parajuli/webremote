pub mod apps;
mod index;
pub mod keyboard;
pub mod templates;
pub mod wm;
mod webserver;
mod command_line;
mod pulse;
pub mod messages;

use std::{path::Path, sync::Arc};
use axum::extract::ws::Message;
use tokio::sync::{Mutex, broadcast::{self, Sender}};

use crate::{apps::Config, pulse::PulseState};

const DIST: &str = "./dist";

#[derive(Debug, Clone)]
pub struct AppState {
    config: &'static Config,
    pulse_state: PulseState,
    broadcast: Arc<Mutex<Sender<Message>>>
}

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let args = command_line::parse_options();
    let interface = format!("{}:{}", args.interface, args.port);

    let dist_dir = if Path::new(DIST).exists() {
        DIST
    } else {
        "./public"
    };

    let config: &'static Config = Box::leak(Box::new(Config::load(args.config)));
    let pulse_state = PulseState::new().await.unwrap();

    let (tx, _) = broadcast::channel(32);
    let broadcast = Arc::new(Mutex::new(tx));

    let state = AppState { config, pulse_state, broadcast };

    webserver::serve(state, dist_dir, &interface).await;
}
