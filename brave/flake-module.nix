let
  packageName = "brave";
in
{
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    let
      isSupportedSystem = (
        builtins.elem system [
          "x86_64-linux"
          "aarch64-linux"
        ]
      );
    in
    {
      packages = lib.optionalAttrs isSupportedSystem {
        ${packageName} =
          (pkgs.${packageName}.override {
            commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation";
          }).overrideAttrs
            (old: {
              # NOTE: Brave and websites do not obey LC_TIME as of 2026-04-07
              preFixup = (old.preFixup or "") + ''
                gappsWrapperArgs+=(
                  --set LC_ALL en_IE.UTF-8
                )
              '';
            });
      };
    };
}
