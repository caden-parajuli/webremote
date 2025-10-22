{
  description = "A web-based remote control for your HTPC";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{
      nixpkgs,
      flake-utils,
      flake-parts,
      ...
    }:
    (flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Development ppackages
          devShells.default =
            with pkgs;
            mkShell rec {
              nativeBuildInputs = [
                # OCaml
                ocaml
                opam
                dune_3
                ocamlPackages.ocamlformat
                ocamlPackages.tyxml

                # Client
                nodejs
                emmet-language-server
                typescript-language-server
                prettierd
                typescript

                # Dream deps
                libev
                openssl
                pkg-config
                gmp
              ];
              buildInputs = [
                pkg-config
                gmp

                ydotool
              ];
              LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
            };
          packages = rec {
            webremote = pkgs.callPackage ./package.nix { };
            default = webremote;
          };
        };

    }) // {
      nixosModule = ./webremote.nix;
    };
}
