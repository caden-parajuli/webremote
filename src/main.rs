mod index;
pub mod templates;
pub mod keyboard;
pub mod apps;
pub mod wm;

use axum::Router;
use axum::routing::get;
use mime::Mime;
use tower_http::services::{ServeDir, ServeFile};

use crate::index::index;

#[tokio::main]
async fn main() {
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080")
        .await
        .expect("Error binding port");

    axum::serve(listener, app().into_make_service())
        .await
        .expect("Error starting server");
}

fn app() -> Router {
    let public = ServeDir::new("./public");

    let favicon = ServeFile::new("./public/icons/favicon.ico");
    let service_worker = ServeFile::new("./public/service-worker.js");
    let manifest = ServeFile::new_with_mime(
        "./public/manifest.json",
        &"application/manifest+json".parse::<Mime>().unwrap(),
    );

    Router::new()
        .route("/", get(index))
        .nest_service("/favicon.ico", favicon)
        .nest_service("/service-worker.js", service_worker)
        .nest_service("/manifest.json", manifest)
        .nest_service("/public", public.clone())
        .nest_service("/static", public)
}
