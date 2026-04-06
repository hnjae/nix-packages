let
  packageName = "cider";
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
      packages.${packageName} = lib.mkIf (system == "x86_64-linux") (
        pkgs.callPackage ./derivation.nix { }
      );
    };
}
