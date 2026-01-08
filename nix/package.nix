{
  pkgs,
  lib,
  rustPlatform,
  stdenv,
  ...
}:
rustPlatform.buildRustPackage(finalAttrs: {
  pname = "webremote";
  version = "0.2.0";
  
  src = ./..;

  cargoHash = "sha256-dUxW/d4RF838sbYbLYvXeVJtFketsVIsKjp4eOduWD8=";

  postInstall = ''
     mkdir -p ./public
     mkdir -p ./dist
     cp -r ./public $out/public
     cp -r ./dist $out/dist
     '';

  nativeBuildInputs = with pkgs; [
    openssl
    pkg-config
  ];
  buildInputs = with pkgs; [
    dbus

    ydotool
  ];
  propogatedBuildInputs = with pkgs; [
    ydotool
  ];

  meta = {
    description = "A web-based remote control for your HTPC with PWA support.";
    homepage = "https://github.com/caden-parajuli/webremote";
    license = lib.licenses.mit;
    maintainers = [ ];
  };
})
