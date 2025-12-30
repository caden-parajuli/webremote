use std::process::Command;

use serde::{Deserialize, Serialize};
use swayipc::{Connection, Error};

use crate::apps::App;

#[derive(Debug, Clone, Copy, Default, Serialize, Deserialize)]
pub enum WindowManager {
    #[default]
    Sway,
    Hypr,
}

impl WindowManager {
    pub fn switch_ws(&self, ws: usize) -> Result<(), Error> {
        match self {
            WindowManager::Sway => {
                let mut connection = Connection::new()?;
                _ = self.sway_switch_ws(&mut connection, ws);
            }
            WindowManager::Hypr => {
                let ws = ws.to_string();

                _ = Command::new("hyprctl")
                    .args(["dispatch", "command", "workspace", &ws])
                    .spawn();
            }
        };

        Ok(())
    }

    pub fn goto_app(&self, app: &App) {
        match self {
            WindowManager::Sway => {
                let mut connection = match Connection::new() {
                    Ok(conn) => conn,
                    Err(_) => {
                        return;
                    }
                };
                _ = self.sway_goto_app(&mut connection, app);
            }
            WindowManager::Hypr => {
                let ws = match app.default_workspace {
                    Some(ws) => ws.to_string(),
                    None => {
                        return;
                    }
                };

                _ = Command::new("hyprctl")
                    .args(["dispatch", "command", "workspace", &ws])
                    .spawn();
            }
        };
    }

    fn sway_switch_ws(&self, connection: &mut Connection, ws: usize) -> Result<(), Error> {
        let mut ws = ws.to_string();

        ws.insert_str(0, "workspace ");
        for outcome in connection.run_command(&ws)? {
            outcome?;
        }
        Ok(())
    }

    /// Find what workspace an app is running in, if any
    fn sway_find_app(&self, app_name: &str, connection: &mut Connection) -> (Option<usize>, usize) {
        let tree = match connection.get_tree() {
            Ok(tree) => tree,
            Err(_) => {
                return (None, usize::MAX);
            }
        };

        let mut ws: usize = usize::MAX;
        let mut focused: usize = usize::MAX;
        for node in tree.iter() {
            match node.node_type {
                swayipc::NodeType::Workspace => {
                    if let Some(name) = &node.name {
                        ws = name.parse::<usize>().unwrap_or(ws);

                        if node.focused {
                            focused = ws;
                        }
                    }
                }
                swayipc::NodeType::Con | swayipc::NodeType::FloatingCon => {
                    if let Some(app_id) = node.app_id.as_ref()
                        && app_id == app_name
                    {
                        return (Some(ws), focused);
                    }
                }
                _ => (),
            }
        }
        (None, focused)
    }

    fn sway_goto_app(&self, connection: &mut Connection, app: &App) -> Result<(), Error> {
        let app_name = &app.name;

        match self.sway_find_app(app_name, connection) {
            (Some(ws), _) => self.sway_switch_ws(connection, ws),
            (None, focused_ws) => {
                let ws = app.default_workspace.unwrap_or(focused_ws);
                self.sway_switch_ws(connection, ws)?;

                Ok(app.spawn()?)
            }
        }
    }
}
