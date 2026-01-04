use hyprland::{
    data::Clients,
    dispatch::{Dispatch, DispatchType, FirstEmpty, WorkspaceIdentifierWithSpecial},
    error::HyprError,
    shared::HyprData,
};
use serde::{Deserialize, Serialize};
use swayipc::{Connection, Error};
use tracing::{error, info, warn};

use crate::apps::App;

#[derive(Debug, Clone, Copy, Default, Serialize, Deserialize)]
pub enum WindowManager {
    #[default]
    Sway,
    Hypr,
}

#[derive(Debug)]
pub enum WmError {
    Sway(Error),
    Hypr(HyprError),
}

impl From<Error> for WmError {
    fn from(value: Error) -> Self {
        Self::Sway(value)
    }
}

impl From<HyprError> for WmError {
    fn from(value: HyprError) -> Self {
        Self::Hypr(value)
    }
}

impl WindowManager {
    pub async fn switch_ws(&self, ws: usize) -> Result<(), WmError> {
        match self {
            WindowManager::Sway => {
                let mut connection = Connection::new()?;
                _ = self.sway_switch_ws(&mut connection, ws);
            }
            WindowManager::Hypr => self.hypr_switch_ws(ws).await?,
        };

        Ok(())
    }

    pub async fn goto_app(&self, app: &App) {
        match self {
            WindowManager::Sway => {
                let mut connection = match Connection::new() {
                    Ok(conn) => conn,
                    Err(_) => {
                        return;
                    }
                };
                if let Err(err) = self.sway_goto_app(&mut connection, app) {
                    warn!("Sway goto app: {}", err);
                }
            }
            WindowManager::Hypr => {
                if let Err(err) = self.hypr_goto_app(app).await {
                    warn!("Hyprland goto app: {}", err);
                }
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

    async fn hypr_switch_ws(&self, ws: usize) -> Result<(), HyprError> {
        Dispatch::call_async(DispatchType::Workspace(WorkspaceIdentifierWithSpecial::Id(
            ws as i32,
        )))
        .await?;

        Ok(())
    }

    /// Find what workspace an app is running in, if any. Otherwise it returns
    /// the focused workspace.
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

    async fn hypr_find_app(&self, app_name: &str) -> Option<usize> {
        let clients = match Clients::get_async().await {
            Ok(it) => it,
            Err(err) => {
                error!("Hyprland find app: {}", err);
                return None;
            }
        };
        for client in clients.iter() {
            if client.class.as_str() == app_name {
                return Some(client.workspace.id as usize);
            }
        }
        None
    }

    fn sway_goto_app(&self, connection: &mut Connection, app: &App) -> Result<(), Error> {
        match self.sway_find_app(&app.app_id, connection) {
            (Some(ws), _) => self.sway_switch_ws(connection, ws),
            (None, focused_ws) => {
                let ws = app.default_workspace.unwrap_or(focused_ws);
                self.sway_switch_ws(connection, ws)?;

                Ok(app.spawn()?)
            }
        }
    }

    async fn hypr_goto_app(&self, app: &App) -> Result<(), HyprError> {
        match self.hypr_find_app(&app.app_id).await {
            Some(ws) => self.hypr_switch_ws(ws).await,
            None => {
                match app.default_workspace {
                    Some(ws) => self.hypr_switch_ws(ws).await?,
                    None => {
                        Dispatch::call_async(DispatchType::Workspace(
                            WorkspaceIdentifierWithSpecial::Empty(FirstEmpty {
                                on_monitor: true,
                                next: false,
                            }),
                        ))
                        .await?;
                    }
                }

                info!("Spawning app");
                Ok(app.spawn()?)
            }
        }
    }
}
