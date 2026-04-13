let
  packageName = "comment-checker";
in
{
  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    let
      supportedSystems = lib.platforms.unix;
    in
    {
      packages = lib.optionalAttrs (builtins.elem system supportedSystems) {
        ${packageName} = pkgs.callPackage ./derivation.nix { inherit supportedSystems; };
      };
    };
}
