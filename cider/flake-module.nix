let
  packageName = "cider";
  supportedSystems = [ "x86_64-linux" ];
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
      packages = lib.optionalAttrs (builtins.elem system supportedSystems) {
        ${packageName} = pkgs.callPackage ./derivation.nix { inherit supportedSystems; };
      };
    };
}
