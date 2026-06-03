use std::{process::Command};
use tracing::{warn, error};

/// Attempts to run `pactl info`.
/// This can force PulseAudio to create the pulse cookie file in
/// cases where it does not exist (e.g. first boot of a fresh OS install)
pub fn pactl_info() {
    _ = Command::new("pactl").args(["info"]).status();
}

pub fn try_ydotool<'a, I>(args: I) where I: IntoIterator<Item = &'a str> {
    warn!("ydotool running:");
    match Command::new("ydotool").args(args).status() {
        Ok(status) => {
            if !status.success() {
                match status.code() {
                    Some(code) => warn!("ydotool exited with status code {code}"),
                    None => warn!("ydotool terminated by signal")
                }
            } else {
                warn!("ydotool worked!")
            }
        },
        Err(e) => {
            error!("Failed to spawn ydotool: {e}");
        },
    }
}
