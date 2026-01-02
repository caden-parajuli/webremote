use axum::extract::ws::{Message, WebSocket};
use axum::extract::{State, WebSocketUpgrade};
use axum::middleware;
use axum::routing::get;
use axum::{Router, extract::Request};
use futures_util::{
    SinkExt, StreamExt,
    stream::{SplitSink, SplitStream},
};
use mime::Mime;
use std::path::Path;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::sync::broadcast::Receiver;
use tower_http::services::{ServeDir, ServeFile};
use tracing::{error, info};

use crate::AppState;
use crate::index::index;
use crate::messages::ClientMessage;

pub async fn serve(state: AppState, dist_dir: &str, interface: &str) {
    let listener = tokio::net::TcpListener::bind(interface)
        .await
        .expect("Error binding port");

    axum::serve(listener, app(state, dist_dir).into_make_service())
        .await
        .expect("Error starting server");
}

fn app(state: AppState, dist_dir: &str) -> Router {
    let public = ServeDir::new("./public");
    let dist = ServeDir::new(dist_dir);

    let favicon = ServeFile::new("./public/icons/favicon.ico");
    let service_worker = ServeFile::new(Path::new(dist_dir).join("service-worker.js"));
    let manifest = ServeFile::new_with_mime(
        "./public/manifest.json",
        &"application/manifest+json".parse::<Mime>().unwrap(),
    );

    Router::new()
        .route("/", get(index))
        .route("/ws", get(upgrade_handler))
        .with_state(state)
        .layer(middleware::from_fn(log_index))
        .nest_service("/favicon.ico", favicon)
        .nest_service("/service-worker.js", service_worker)
        .nest_service("/manifest.json", manifest)
        .nest_service("/public", public)
        .nest_service("/dist", dist)
}

async fn upgrade_handler(
    ws: WebSocketUpgrade,
    State(state): State<AppState>,
) -> axum::http::Response<axum::body::Body> {
    info!("Upgrade");
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

async fn handle_socket(socket: WebSocket, mut state: AppState) {
    let (tx, rx) = socket.split();
    let ws_tx = Arc::new(Mutex::new(tx));

    let broadcast_reader = state.broadcast.lock().await.subscribe();
    let tx_for_broadcast = ws_tx.clone();
    tokio::spawn(async move {
        recv_broadcast(tx_for_broadcast, broadcast_reader).await;
    });

    recv_from_client(ws_tx, rx, &mut state).await
}

async fn recv_from_client(
    client_tx: Arc<Mutex<SplitSink<WebSocket, Message>>>,
    mut client_rx: SplitStream<WebSocket>,
    state: &mut AppState,
) {
    while let Some(Ok(msg)) = client_rx.next().await {
        if matches!(msg, Message::Close(_)) {
            return;
        }

        let msg_text = match msg.to_text() {
            Ok(it) => it,
            Err(err) => {
                error!("Getting message text: {}", err);
                continue;
            }
        };
        info!("Message: {}", msg_text);

        let (is_broadcast, response_opt) = match ClientMessage::parse(msg_text) {
            Ok(message) => message,
            Err(err) => {
                error!("Parsing: {}", err);
                continue;
            }
        }
        .handle(state).await;

        if let Some(response) = response_opt {
            let response_msg: Message = match serde_json::to_string(&response) {
                Ok(it) => it.into(),
                Err(err) => {
                    error!("Serializing response: {}", err);
                    continue;
                }
            };
            if is_broadcast {
                if let Err(err) = state.broadcast.lock().await.send(response_msg) {
                    info!("{}", err);
                }
            } else if let Err(err) = client_tx.lock().await.send(response_msg).await {
                info!("{}", err);
            }
        }
    }
}

async fn recv_broadcast(
    client_tx: Arc<Mutex<SplitSink<WebSocket, Message>>>,
    mut broadcast_rx: Receiver<Message>,
) {
    while let Ok(msg) = broadcast_rx.recv().await {
        if let Err(err) = client_tx.lock().await.send(msg).await {
            info!("Sending broadcast: {}", err);
            return;
        }
    }
}

//
// Middleware
//

async fn log_index(req: Request, next: axum::middleware::Next) -> axum::response::Response {
    let uri = req.uri();

    if uri == "/" {
        info!("{} {} {:?}", req.method(), uri, req.version());
    }

    // Return the response
    next.run(req).await
}
