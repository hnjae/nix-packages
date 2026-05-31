{
  description = "Packages that are either not in nixpkgs or not packaged to our taste.";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/0"; # Stable nixpkgs
  };

  outputs =
    { nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      packageFiles = {
        brave = ./brave/package.nix;
        cider = ./cider/package.nix;
        claude-desktop = ./claude-desktop/package.nix;
        comment-checker = ./comment-checker/package.nix;
        kdecodexbar = ./kdecodexbar/package.nix;
        libheif = ./libheif/package.nix;
        obsidian = ./obsidian/package.nix;
        opencode-desktop = ./opencode-desktop/package.nix;
      };

      packagesFor =
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          packages = lib.mapAttrs (_: packageFile: pkgs.callPackage packageFile { }) packageFiles;
        in
        lib.filterAttrs (_: package: lib.meta.availableOn pkgs.stdenv.hostPlatform package) packages;
    in
    {
      packages = lib.genAttrs systems packagesFor;
    };
}
