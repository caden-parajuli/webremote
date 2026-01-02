use std::str::FromStr;

use axum::extract::ws::{Message, WebSocket};
use futures_util::{SinkExt, stream::SplitSink};
use mpris::{FindingError, PlayerFinder};
use serde::{Deserialize, Serialize};
use tokio::sync::{Mutex, broadcast::Sender};
use tracing::error;

use crate::{
    AppState,
    keyboard::{Key, type_string},
};

#[derive(Serialize, Deserialize, Debug)]
pub enum ClientMessage {
    // Keybord
    PushKey { key: String },
    ReleaseKey { key: String },
    PressKey { key: String },
    Type { message: String },

    // Apps
    GotoApp { name: String },

    // Audio
    GetVolume,
    SetVolume { value: usize },
    AdjustVolume { delta: isize },

    // MPRIS
    Pause,
    Play,
    PlayPause,
    Stop,
}

impl ClientMessage {
    pub fn parse(message: &str) -> Result<ClientMessage, serde_json::Error> {
        serde_json::from_str(message)
    }

    pub async fn handle(&self, state: &mut AppState) -> (bool, Option<ServerMessage>) {
        match self {
            ClientMessage::PushKey { key } => {
                let key = match Key::from_str(key) {
                    Ok(it) => it,
                    Err(_) => return (false, None),
                };

                key.push();
            }
            ClientMessage::ReleaseKey { key } => {
                let key = match Key::from_str(key) {
                    Ok(it) => it,
                    Err(_) => return (false, None),
                };

                key.release();
            }
            ClientMessage::PressKey { key } => {
                let key = match Key::from_str(key) {
                    Ok(it) => it,
                    Err(_) => return (false, None),
                };

                key.press();
            }
            ClientMessage::Type { message } => type_string(message),
            ClientMessage::GotoApp { name } => {
                let config = state.config;
                if let Some(app) = config.find_app_by_name(name) {
                    app.switch_to(&config.window_manager);
                }
            }
            ClientMessage::GetVolume => match state.pulse_state.get_volume().await {
                Ok(volume) => {
                    return (false, Some(ServerMessage::Volume { level: volume }));
                }
                Err(err) => error!("Get volume: {:#?}", err),
            },
            ClientMessage::SetVolume { value } => {
                match state.pulse_state.set_volume(*value).await {
                    Ok(_) => (),
                    Err(err) => error!("Set volume: {:#?}", err),
                }
            }
            ClientMessage::AdjustVolume { delta } => {
                match state.pulse_state.adjust_volume(*delta).await {
                    Ok(_) => (),
                    Err(err) => error!("Adjust volume: {:#?}", err),
                }
            }
            ClientMessage::Pause
            | ClientMessage::Play
            | ClientMessage::PlayPause
            | ClientMessage::Stop => {
                if let Err(err) = self.handle_mpris_message() {
                    error!("MPRIS: {}", err)
                }
            }
        }
        (false, None)
    }

    fn handle_mpris_message(&self) -> Result<(), FindingError> {
        let player_finder = PlayerFinder::new()?;
        let player = player_finder.find_active()?;

        let () = match self {
            ClientMessage::Pause => player.pause()?,
            ClientMessage::Play => player.play()?,
            ClientMessage::PlayPause => player.play_pause()?,
            ClientMessage::Stop => player.stop()?,
            _ => (),
        };
        Ok(())
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy)]
#[serde(tag = "type")]
pub enum ServerMessage {
    Volume { level: usize },
}

impl ServerMessage {
    pub async fn broadcast(&self, broadcaster: &Mutex<Sender<Message>>) {
        let msg: Message = match serde_json::to_string(self) {
            Ok(it) => it.into(),
            Err(err) => {
                error!("Serializing broadcast: {}", err);
                return;
            }
        };

        if let Err(err) = broadcaster.lock().await.send(msg) {
            error!("Sending broadcast: {}", err);
        }
    }

    pub async fn send(&self, client_tx: &Mutex<SplitSink<WebSocket, Message>>) {
        let msg: Message = match serde_json::to_string(self) {
            Ok(it) => it.into(),
            Err(err) => {
                error!("Serializing broadcast: {}", err);
                return;
            }
        };

        if let Err(err) = client_tx.lock().await.send(msg).await {
            error!("Sending broadcast: {}", err);
        }
    }
}
