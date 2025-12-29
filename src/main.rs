mod index;

use axum::Router;
use axum::routing::get;

use crate::index::index;

#[tokio::main]
async fn main() {
    let app = Router::new().route("/", get(index));

    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080")
        .await
        .expect("Error binding port");

    axum::serve(listener, app.into_make_service())
        .await
        .expect("Error starting server");
}
