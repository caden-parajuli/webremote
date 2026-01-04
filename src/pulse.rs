use std::{iter::repeat_n, sync::Arc, time::Duration};

use axum::extract::ws::Message;
use pulseaudio::{
    Client, ClientError,
    protocol::{ChannelVolume, DEFAULT_SINK, SubscriptionMask, Volume},
};
use tokio::sync::{Mutex, broadcast::Sender};
use tracing::info;

use crate::{async_utils::retry_exponential, messages::ServerMessage};

const VOLUME_NORM: u32 = 0x10000;

#[derive(Debug, Clone)]
pub struct PulseState {
    client: Client,
}

impl Default for PulseState {
    fn default() -> Self {
        Self::new().unwrap()
    }
}

impl PulseState {
    pub fn new() -> Result<Self, ClientError> {
        let client = Client::from_env(c"WebRemote")?;
        Ok(PulseState { client })
    }
    pub async fn new_retry(
        runtime: &tokio::runtime::Runtime,
        retries: usize,
    ) -> Result<Self, ClientError> {
        let initial_wait = Duration::from_millis(500);

        let client = retry_exponential(
            async |_| {
                info!("Attempting to connect to PulseAudio");
                runtime
                    .spawn_blocking(|| Client::from_env(c"WebRemote"))
                    .await
                    .unwrap()
            },
            (),
            retries,
            initial_wait,
        )
        .await?;

        Ok(PulseState { client })
    }

    pub async fn get_volume(&self) -> Result<usize, ClientError> {
        let info = self
            .client
            .sink_info_by_name(DEFAULT_SINK.to_owned())
            .await?;
        Ok(average_cvolume(&info.cvolume))
    }

    pub async fn set_volume(&self, level: usize) -> Result<(), ClientError> {
        let info = self
            .client
            .sink_info_by_name(DEFAULT_SINK.to_owned())
            .await?;
        let num_channels = info.cvolume.channels().len();

        self.client
            .set_sink_volume_by_name(DEFAULT_SINK.to_owned(), set_cvolume(num_channels, level))
            .await?;
        Ok(())
    }

    pub async fn adjust_volume(&self, delta: isize) -> Result<(), ClientError> {
        let info = self
            .client
            .sink_info_by_name(DEFAULT_SINK.to_owned())
            .await?;
        let old = info.cvolume;

        self.client
            .set_sink_volume_by_name(DEFAULT_SINK.to_owned(), adjust_cvolume(&old, delta))
            .await?;
        Ok(())
    }

    pub async fn subscribe_volume(
        &'static self,
        runtime: tokio::runtime::Runtime,
        broadcaster: Arc<Mutex<Sender<Message>>>,
    ) -> Result<(), ClientError> {
        let broadcaster = Arc::clone(&broadcaster);

        self.client
            .subscribe(
                SubscriptionMask::SINK,
                Box::new(move |_| {
                    let broadcaster = Arc::clone(&broadcaster);
                    runtime.spawn(async move {
                        if let Ok(volume) = self.get_volume().await {
                            ServerMessage::Volume { level: volume }
                                .broadcast(&broadcaster)
                                .await;
                        }
                    });
                }),
            )
            .await
    }
}

fn adjust_cvolume(old: &ChannelVolume, delta: isize) -> ChannelVolume {
    ChannelVolume::new(old.channels().iter().map(|v| {
        let new_v = if delta > 0 {
            v.as_u32() + level_to_raw(delta as usize)
        } else {
            v.as_u32() - level_to_raw(-delta as usize)
        };

        Volume::from_u32_clamped(new_v)
    }))
}

fn set_cvolume(num_channels: usize, level: usize) -> ChannelVolume {
    ChannelVolume::new(repeat_n(
        Volume::from_u32_clamped(level_to_raw(level)),
        num_channels,
    ))
}

fn average_cvolume(cvolume: &ChannelVolume) -> usize {
    let channels = cvolume.channels();
    let mut sum = 0;
    for channel in channels {
        sum += channel.as_u32();
    }

    percent_to_level(raw_to_percent(sum) / channels.len() as f32)
}

fn percent_to_level(percent: f32) -> usize {
    (percent * 100.0).round() as usize
}

fn raw_to_percent(raw: u32) -> f32 {
    raw as f32 / VOLUME_NORM as f32
}

fn level_to_raw(level: usize) -> u32 {
    ((level as f32 / 100.0) * VOLUME_NORM as f32) as u32
}
