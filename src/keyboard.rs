use std::{fmt::Display, process::Command, str::FromStr};

const ENTER: usize = 28;
const UP: usize = 103;
const LEFT: usize = 105;
const RIGHT: usize = 106;
const DOWN: usize = 108;
const BACK: usize = 1;

#[derive(Clone, Copy, Debug)]
pub enum Key {
    Up,
    Left,
    Right,
    Down,
    Enter,
    Back,
}

impl Display for Key {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let str = match self {
            Key::Up => "up",
            Key::Left => "left",
            Key::Right => "right",
            Key::Down => "down",
            Key::Enter => "enter",
            Key::Back => "back",
        };
        write!(f, "{}", str)
    }
}

impl FromStr for Key {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(match s {
            "up" => Key::Up,
            "left" => Key::Left,
            "right" => Key::Right,
            "down" => Key::Down,
            "enter" => Key::Enter,
            "back" => Key::Back,
            _ => return Err(()),
        })
    }
}

impl From<Key> for usize {
    fn from(val: Key) -> Self {
        match val {
            Key::Up => UP,
            Key::Left => LEFT,
            Key::Right => RIGHT,
            Key::Down => DOWN,
            Key::Enter => ENTER,
            Key::Back => BACK,
        }
    }
}

impl Key {
    pub fn display(self) -> &'static str {
        match self {
            Key::Up => "Up",
            Key::Left => "Left",
            Key::Right => "Right",
            Key::Down => "Down",
            Key::Enter => "Enter",
            Key::Back => "Back",
        }
    }

    pub fn key_down(self) {
        let down_arg = self.to_string() + ":1";

        _ = Command::new("ydotool").args(["key", &down_arg]).spawn();
    }

    pub fn key_up(self) {
        let up_arg = self.to_string() + ":0";

        _ = Command::new("ydotool").args(["key", &up_arg]).spawn();
    }

    pub fn press(self) {
        let down_arg = self.to_string().to_owned().clone() + ":1";
        let up_arg = self.to_string().to_owned() + ":0";

        _ = Command::new("ydotool")
            .args(["key", &down_arg, &up_arg])
            .spawn();
    }
}

pub fn type_string(text: &str) {
    _ = Command::new("ydotool")
        .args(["type", text, "-d", "2ms"])
        .spawn();
}
