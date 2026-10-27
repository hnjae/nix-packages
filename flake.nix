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
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

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
            otf-interop = ./otf-interop/package.nix;
            otf-kopub-world = ./otf-kopub-world/package.nix;
            otf-plangothic = ./otf-plangothic/package.nix;
            otf-ridibatang = ./otf-ridibatang/package.nix;
            ttf-dmca-sans-serif = ./ttf-dmca-sans-serif/package.nix;
            ttf-freesentation = ./ttf-freesentation/package.nix;
            ttf-hcr = ./ttf-hcr/package.nix;
            ttf-monoplex-cjk = ./ttf-monoplex-cjk/package.nix;
            ttf-monoplex-cjk-nerd-font = ./ttf-monoplex-cjk-nerd-font/package.nix;
            ttf-pretendard-gov-variable = ./ttf-pretendard-gov-variable/package.nix;
            ttf-sarasa-fixed-k-nerd-font = ./ttf-sarasa-fixed-k-nerd-font/package.nix;
          };

          packages = lib.mapAttrs (_: packageFile: pkgs.callPackage packageFile { }) packageFiles;

          formatters = with pkgs; [
            biome
            just
            nixfmt
            rumdl
            shellcheck
            shellharden
            shfmt
            taplo
            treefmt
            yamlfmt
          ];
        in
        {
          packages = lib.filterAttrs (
            _: package: lib.meta.availableOn pkgs.stdenv.hostPlatform package
          ) packages;

          formatter = pkgs.writeShellApplication {
            name = "treefmt";
            runtimeInputs = formatters;
            text = ''
              exec treefmt "$@"
            '';
          };

          devShells.default = pkgs.mkShellNoCC {
            packages =
              formatters
              ++ [
                pkgs.cocogitto
                pkgs.deadnix
                pkgs.fzf
                pkgs.gh
                pkgs.jq
                pkgs.nixd
                pkgs.prek
                pkgs.statix
                pkgs.typos
                pkgs.vulnix
              ]
              ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
                pkgs.dpkg
                pkgs.xeyes
                pkgs.xprop
                pkgs.xvfb
                pkgs.xwininfo
              ];

            shellHook = ''
              prek install --quiet
            '';
          };

          checks.format =
            pkgs.runCommandLocal "format-check"
              {
                nativeBuildInputs = formatters ++ [ pkgs.typos ];
              }
              ''
                cp -r ${./.} work
                chmod -R u+w work
                cd work
                export HOME="$TMPDIR"
                treefmt --ci
                typos
                touch "$out"
              '';
        };
    };
}
