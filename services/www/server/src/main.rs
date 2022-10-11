use std::io::Write;

use base64::encode;
use flate2::write::GzEncoder;
use flate2::Compression;
use mime_guess;
use rust_embed::RustEmbed;

// Pull in all the AssemblyLift guest helpers, such as the handler macro
use asml_core::*;
// Pull in helpers for the HTTP IOmod
use http;

// The handler attribute macro initializes this as an AssemblyLift function, and allows use of `await`
#[handler]
pub fn main() {
    // The `ctx` variable is provided by the handler macro; input is always JSON
    let event: serde_json::Value = serde_json::from_str(&ctx.input)
        .expect("could not parse function input as JSON");
    let path = event["rawPath"]
        .as_str()
        .expect("could not parse rawPath");
    let path = match path.ends_with("/") {
        true => format!("{}index.html", &path[1..path.len()]),
        false => String::from(&path[1..path.len()]),
    };

    let ip = event["requestContext"]["http"]["sourceIp"]
        .as_str()
        .expect("could not parse sourceIp");

    FunctionContext::log(format!("Serving {:?}", path.clone()));

    // Match the requested path against our local assets and serve the result if found
    match AppAssets::get(&path.clone()) {
        Some(asset) => {
            let mut gzip = GzEncoder::new(Vec::new(), Compression::default());
            let mime = format!("{}; charset=utf-8", mime_guess::from_path(path.clone())
                .first_or_octet_stream()
                .as_ref()
                .to_string());
            let data = asset.data.as_ref();
            gzip.write_all(data).unwrap();
            let body = encode(gzip.finish().unwrap());
            http_ok!(body, Some(mime), true, true) // true, true: gzip & encode base64

        }
        None => http_not_found!(path.clone()),
    }

    // We count visits to the homepage AFTER we have replied OK to the client
    if path.contains("index.htm") {
        if let Err(err) = count_visit(ip.to_string()).await {
            FunctionContext::log(format!("ERR {:?}", err));
        }
    }
}

async fn count_visit(ip: String) -> Result<http::structs::HttpResponse, http::Error> {
    let req = http::HttpRequestBuilder::new()
        .method("POST")
        .host("nextjs.demos.asml.akkoro.io")
        .path(&format!("/api/counter/{}", &ip))
        .content_type("application/json")
        .auth("iam", Default::default())
        .body("{}")
        .build();
    http::request(req).await
}

#[derive(RustEmbed)]
#[folder = "../../../frontend/www/out"]
struct AppAssets;
