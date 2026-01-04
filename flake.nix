{
  description = "A web-based remote control for your HTPC";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = [
              inputs.rust-overlay.overlays.default
            ];
            config = { };
          };

          # Development ppackages
          devShells.default =
            with pkgs;
            mkShell rec {
              nativeBuildInputs = [
                pkg-config
                dbus

                nodejs
                emmet-language-server
                typescript-language-server
                prettierd
                typescript
              ];
              buildInputs = [
                (rust-bin.stable.latest.default.override {
                  extensions = [
                    "rust-src"
                    "rust-analyzer"
                  ];
                })

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
