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
                ocamlPackages.ctypes
                ocamlPackages.ctypes-foreign
                ocamlPackages.utop

                # Client
                nodejs
                emmet-language-server
                typescript-language-server
                prettierd
                typescript

                pkg-config
              ];
              buildInputs = [
                libev
                openssl
                gmp

                libffi
                libpulseaudio

                ydotool
              ];
              LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
            };
          packages = rec {
            webremote = pkgs.callPackage ./nix/package.nix { };
            default = webremote;
          };
          checks =
            let
              checkArgs = rec {
                pkgs = nixpkgs.legacyPackages.${system};
                lib = pkgs.lib;

                inherit self';
                inherit config;
              };
            in
            {
              minimal-test = import ./nix/test.nix checkArgs;
            };
        };

    })
    // rec {
      nixosModule = ./nix/service.nix;
      nixosModules.default = nixosModule;
    };
}
