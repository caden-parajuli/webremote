use std::{
    io::{Error, ErrorKind},
    process::{Command, Stdio},
};

use confy::ConfigStrategy;
use serde::{Deserialize, Serialize};

use crate::wm::WindowManager;

const CONFIG_NAME: &str = "config";

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct App {
    /// Used in code
    pub name: String,
    /// Displayed to user
    pub pretty_name: String,
    /// The app id as reported by the window manager
    pub app_id: String,
    pub launch_command: String,
    /// Not needed for apps with builtin support
    /// TODO: document how to create an SVG for these
    pub icon_path: Option<String>,
    pub default_workspace: Option<usize>,
}

impl App {
    fn new(
        name: String,
        pretty_name: String,
        app_id: String,
        launch_command: String,
        icon_path: Option<String>,
        default_workspace: Option<usize>,
    ) -> Self {
        Self {
            name,
            pretty_name,
            app_id,
            launch_command,
            icon_path,
            default_workspace,
        }
    }
}

impl App {
    pub async fn switch_to(&self, wm: &WindowManager) {
        wm.goto_app(self).await;
    }

    pub fn spawn(&self) -> Result<(), Error> {
        let parsed_command = shell_words::split(&self.launch_command)
            .or(Err(Error::new(ErrorKind::Other, "Command parse error")))?;

        let mut args = parsed_command.iter();
        if let Some(command) = args.next() {
            let _ = Command::new(command)
                .args(args)
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .spawn();
            Ok(())
        } else {
            Err(Error::new(ErrorKind::Other, "No launch command"))
        }
    }

    pub fn icon_path(&self) -> String {
        match self.icon_path.clone() {
            Some(path) => path + "#symbol",
            None => {
                format!("/public/icons/apps/{}.svg#symbol", self.name)
            }
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    pub window_manager: WindowManager,
    pub apps: Vec<App>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            window_manager: Default::default(),
            apps: vec![
                App::new(
                    String::from("kodi"),
                    String::from("Kodi"),
                    String::from("Kodi"),
                    String::from("kodi"),
                    None,
                    Some(1),
                ),
                App::new(
                    String::from("youtube"),
                    String::from("YouTube"),
                    String::from("vacuumtube"),
                    String::from("VacuumTube"),
                    None,
                    Some(2),
                ),
            ],
        }
    }
}

impl Config {
    pub fn load(path: Option<String>) -> Self {
        confy::change_config_strategy(ConfigStrategy::App);
        match path {
            Some(path) => confy::load_path(path),
            None => confy::load("WebRemote", Some(CONFIG_NAME)),
        }.unwrap_or_else(|_| Self::default())
    }

    pub fn find_app_by_name<'a>(&'a self, app_name: &str) -> Option<&'a App> {
        self.apps.iter().find(|&app| app.name == app_name)
    }
}
