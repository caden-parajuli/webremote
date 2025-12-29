{
  pkgs,
  lib,
  stdenv,
  ...
}:
pkgs.ocamlPackages.buildDunePackage {
  pname = "webremote";
  version = "0.1.0";
  
  src = ./..;

  minimalOCamlVersion = "5.3.0";

  postInstall = ''
     mkdir -p ./public
     mkdir -p ./static
     cp -r ./public $out/public
     cp -r ./static $out/static
     '';

  nativeBuildInputs = with pkgs; [
    openssl
    pkg-config
  ];
  buildInputs = with pkgs; [
    libpulseaudio
    dbus

    ydotool
  ];
  propogatedBuildInputs = with pkgs; [
    ydotool
  ];
}
