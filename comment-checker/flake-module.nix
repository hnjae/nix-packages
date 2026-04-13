let
  packageName = "comment-checker";
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        ${packageName} = pkgs.callPackage ./derivation.nix { };
      };
    };
}
