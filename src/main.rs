pub mod apps;
pub mod async_utils;
mod command_line;
mod index;
pub mod keyboard;
pub mod messages;
mod pulse;
pub mod templates;
mod webserver;
pub mod wm;

use axum::extract::ws::Message;
use std::{path::Path, sync::Arc};
use tokio::sync::{
    Mutex,
    broadcast::{self, Sender},
};

use crate::{apps::Config, pulse::PulseState};

const DIST: &str = "./dist";
const RETRIES: usize = 5;

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

    let rt = tokio::runtime::Runtime::new().unwrap();

    let config: &'static Config = Box::leak(Box::new(Config::load(args.config)));
    let pulse_state = Box::leak(Box::new(PulseState::new().unwrap()));

    let (tx, _) = broadcast::channel(32);
    let broadcast = Arc::new(Mutex::new(tx));

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

// async fn subscribe(pulse_state: &PulseState, broadcaster: Arc<Mutex<Sender<Message>>>) {
//     tokio::spawn(async move {
//         loop {
//             tokio::time::sleep(Duration::from_secs(1)).await;
//             println!("send");
//
//             let new_level = (std::time::SystemTime::now()
//                 .duration_since(std::time::UNIX_EPOCH)
//                 .unwrap_or(Duration::from_nanos(30))
//                 .subsec_nanos()
//                 % 100) as usize;
//
//             ServerMessage::Volume { level: new_level }
//                 .broadcast(broadcaster.as_ref())
//                 .await;
//         }
//     });
// }
