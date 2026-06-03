mod command_line;
mod processes;
mod pulse;
mod webserver;

pub mod apps;
pub mod async_utils;
pub mod keyboard;
pub mod messages;
pub mod pages;
pub mod templates;
pub mod wm;

use axum::extract::ws::Message;
use std::{path::Path, process::exit, sync::Arc};
use tokio::sync::{
    Mutex,
    broadcast::{self, Sender},
};
use tracing::{error, info};

use crate::{apps::Config, processes::pactl_info, pulse::PulseState};

const DIST: &str = "./dist";

#[derive(Debug, Clone)]
pub struct AppState {
    config: &'static Config,
    pulse_state: &'static PulseState,
    broadcast: Arc<Mutex<Sender<Message>>>,
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

    let pulse = match PulseState::new() {
        Ok(p) => p,
        Err(_) => {
            // Last-ditch attempt to fix pulse
            pactl_info();

            match PulseState::new() {
                Ok(p) => p,
                Err(e) => {
                    error!("Failed to create pulse state: {e}");
                    info!("Socket path from env: {:?}", pulseaudio::socket_path_from_env());
                    info!("Cookie path from env: {:?}", pulseaudio::cookie_path_from_env());
                    exit(-1);
                }
            }

        }
    };
    let pulse_state = Box::leak(Box::new(pulse));


    let (tx, _) = broadcast::channel(32);
    let broadcast = Arc::new(Mutex::new(tx));

    let rt = tokio::runtime::Runtime::new().unwrap();

    pulse_state
        .subscribe_volume(rt, Arc::clone(&broadcast))
        .await
        .expect("Couldn't subscribe to volume");

    let state = AppState {
        config,
        pulse_state,
        broadcast,
    };

    webserver::serve(state, dist_dir, &interface).await;
}
