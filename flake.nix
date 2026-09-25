{
  description = "Packages that are either not in nixpkgs or not packaged to our taste.";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0"; # Most recently published stable

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      flake-parts,
      nixpkgs,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ flake-parts.flakeModules.partitions ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      partitions.dev = {
        extraInputsFlake = ./nix/partitions/dev;
        module =
          { inputs, ... }:
          {
            imports = [
              inputs.git-hooks.flakeModule
              inputs.treefmt-nix.flakeModule
            ];

            perSystem =
              { config, pkgs, ... }:
              {
                treefmt = {
                  projectRootFile = "flake.nix";
                  programs = {
                    nixfmt.enable = true;
                    rumdl-format.enable = true;
                    taplo.enable = true;
                    yamlfmt.enable = true;
                    just.enable = true;
                  };

                  settings.formatter.biome = {
                    command = "${pkgs.biome}/bin/biome";
                    options = [
                      "check"
                      "--write"
                      "--no-errors-on-unmatched"
                    ];
                    includes = [
                      "*.js"
                      "*.mjs"
                      "*.cjs"
                      "*.jsx"
                      "*.ts"
                      "*.mts"
                      "*.cts"
                      "*.tsx"
                      "*.json"
                      "*.jsonc"
                      "*.css"
                    ];
                  };

                  settings.formatter.shell-fmt = {
                    command = toString (
                      pkgs.writeShellScript "shell-fmt" ''
                        set -euo pipefail

                        for file in "$@"; do
                          ${pkgs.shellharden}/bin/shellharden --replace "$file"
                          ${pkgs.shellcheck}/bin/shellcheck "$file"
                          ${pkgs.shfmt}/bin/shfmt --indent 4 --simplify --write "$file"
                        done
                      ''
                    );
                    includes = [
                      "*.sh"
                      "*.bash"
                      ".envrc*"
                      ".env*"
                      ".profile"
                    ];
                  };
                };

                pre-commit.settings.package = pkgs.prek;
                pre-commit.settings.hooks = {
                  treefmt.enable = true;
                  detect-private-keys.enable = true;
                  actionlint.enable = true;
                  typos.enable = true;
                };

                devShells.default = pkgs.mkShellNoCC {
                  inputsFrom = [ config.treefmt.build.devShell ];
                  packages = [
                    pkgs.prek
                    pkgs.just
                    pkgs.actionlint
                    pkgs.editorconfig-checker
                    pkgs.statix
                    pkgs.deadnix
                    pkgs.vulnix
                    pkgs.nixd
                    pkgs.typos
                    pkgs.rumdl
                    pkgs.gh
                    pkgs.jq
                    pkgs.fzf
                  ]
                  ++ config.pre-commit.settings.enabledPackages
                  ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                    pkgs.dpkg
                    pkgs.xeyes
                    pkgs.xprop
                    pkgs.xvfb
                    pkgs.xwininfo
                  ];
                  shellHook = config.pre-commit.shellHook + ''
                    if [ ! -e treefmt.toml ] || [ -L treefmt.toml ]; then
                      ln -sf ${config.treefmt.build.configFile} treefmt.toml
                    fi
                  '';
                };
              };
          };
      };

      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
        formatter = "dev";
      };

      perSystem =
        { system, ... }:
        let
          lib = nixpkgs.lib;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          packageFiles = {
            brave = ./brave/package.nix;
            cider = ./cider/package.nix;
            codexbar-cli = ./codexbar-cli/package.nix;
            codexbar-desktop = ./codexbar-desktop/package.nix;
            codexbar-plasmoid = ./codexbar-plasmoid/package.nix;
            hop = ./hop/package.nix;
            libheif = ./libheif/package.nix;
            obsidian = ./obsidian/package.nix;
          };

          packages = lib.mapAttrs (_: packageFile: pkgs.callPackage packageFile { }) packageFiles;
        in
        {
          packages = lib.filterAttrs (
            _: package: lib.meta.availableOn pkgs.stdenv.hostPlatform package
          ) packages;
        };
    };
}
