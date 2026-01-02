use std::str::FromStr;

use serde::{Deserialize, Serialize};
use tracing::{error, info};

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
        info!("Handling: {:#?}", self);

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
                    Ok(_) => match state.pulse_state.get_volume().await {
                        Ok(volume) => {
                            return (true, Some(ServerMessage::Volume { level: volume }));
                        }
                        Err(err) => error!("Get volume: {:#?}", err),
                    },
                    Err(err) => error!("Set volume: {:#?}", err),
                }
            }
            ClientMessage::AdjustVolume { delta } => {
                match state.pulse_state.adjust_volume(*delta).await {
                    Ok(_) => match state.pulse_state.get_volume().await {
                        Ok(volume) => {
                            return (true, Some(ServerMessage::Volume { level: volume }));
                        }
                        Err(err) => error!("Get volume: {:#?}", err),
                    },
                    Err(err) => error!("Adjust volume: {:#?}", err),
                }
            }
            ClientMessage::Pause => todo!(),
            ClientMessage::Play => todo!(),
            ClientMessage::PlayPause => todo!(),
            ClientMessage::Stop => todo!(),
        }
        (false, None)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone, Copy)]
#[serde(tag = "type")]
pub enum ServerMessage {
    Volume { level: usize },
}
