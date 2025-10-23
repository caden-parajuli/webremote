open Webremote

let do_debug _ = Dream.respond ~status:`OK ~code:200 "ran"

let to_manifest handler =
  fun req -> 
    let%lwt message = handler req in
    let () = Dream.set_header message "Content-Type" "application/manifest+json" in
    Lwt.return message

let handle_req =
  let open Dream in
  router
    [
      get "/" (fun _ ->
        Templates.index
          |> Templates.render
          |> Dream.html
      );
      get "/service-worker.js" @@ from_filesystem "./public" "service-worker.js";
      get "/manifest.json" @@ to_manifest @@ from_filesystem "./public" "manifest.json";
      get "/echo/:word" (fun req -> Dream.html @@ param req "word");
      get "/command/test" (fun _ ->
          let _ = Sys.command "echo test > test.out" in
          Dream.html @@ Sys.getcwd ());
      get "/workspace/switch/:ws" (fun req ->
          do_debug @@ WindowManager.switch_workspace @@ param req "ws");
      get "/kbd/press/:key" (fun req ->
          let open Keyboard in
          param req "key" |> getcode |> press_key |> do_debug);
      get "/static/**" @@ Dream.static "./public";
      get "/public/**" @@ Dream.static "./public";
    ]
