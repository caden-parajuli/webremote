{
  pkgs,
  lib,
# fetchurl,
}:

pkgs.ocamlPackages.buildDunePackage rec {
  pname = "yojson-five";
  version = "2.2.2";

  src = pkgs.fetchurl {
    url = "https://github.com/ocaml-community/yojson/releases/download/${version}/yojson-${version}.tbz";
    hash = "sha256-mr+tjJp51HI60vZEjmacHmjb/IfMVKG3wGSwyQkSxZU=";
  };

  propagatedBuildInputs = [
    pkgs.ocamlPackages.yojson
    pkgs.ocamlPackages.seq
    pkgs.ocamlPackages.sedlex
  ];
}
