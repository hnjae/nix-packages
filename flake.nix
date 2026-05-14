{
  description = "Packages that are either not in nixpkgs or not packaged to our taste.";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0"; # Stable nixpkgs
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      imports = [
        ./brave/flake-module.nix
        ./claude-desktop/flake-module.nix
        ./comment-checker/flake-module.nix
        ./cider/flake-module.nix
        ./libheif/flake-module.nix
        ./obsidian/flake-module.nix
        ./opencode-desktop/flake-module.nix
      ];
    };
}
