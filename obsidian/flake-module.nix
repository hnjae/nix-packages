let
  packageName = "obsidian";
in
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") {
        ${packageName} = pkgs.callPackage ./derivation.nix { };
      };
    };
}
