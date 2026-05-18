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
      isSupported = builtins.elem system [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    {
      packages = lib.optionalAttrs isSupported {
        ${packageName} =
          (pkgs.${packageName}.override {
            commandLineArgs = "--enable-features=TouchpadOverscrollHistoryNavigation --class=com.brave.Browser";
          }).overrideAttrs
            (old: {
              postInstall = (old.postInstall or "") + ''
                rm -f $out/share/applications/brave-browser.desktop
                sed -i '/^# This is the same as brave-browser.desktop except NoDisplay=true prevents$/,/^NoDisplay=true$/d' \
                  $out/share/applications/com.brave.Browser.desktop
                substituteInPlace $out/share/applications/com.brave.Browser.desktop \
                  --replace-fail 'Icon=brave-browser' 'Icon=com.brave.Browser'
                substituteInPlace $out/share/gnome-control-center/default-apps/brave-browser.xml \
                  --replace-fail '<icon-name>brave-browser</icon-name>' '<icon-name>com.brave.Browser</icon-name>'
                substituteInPlace $out/share/appdata/brave-browser.appdata.xml \
                  --replace-fail '<id>brave-browser.desktop</id>' '<id>com.brave.Browser.desktop</id>'
                mv $out/share/appdata/brave-browser.appdata.xml \
                  $out/share/appdata/com.brave.Browser.appdata.xml

                for icon in $out/share/icons/hicolor/*x*/apps/brave-browser.png; do
                  mv "$icon" "$(dirname "$icon")/com.brave.Browser.png"
                done

                gzip -cd $out/share/man/man1/brave-browser-stable.1.gz \
                  | sed \
                    -e 's/^\.TH brave-browser 1/.TH com.brave.Browser 1/' \
                    -e 's/^brave-browser \\-/com.brave.Browser \\-/' \
                  | gzip -n > $out/share/man/man1/com.brave.Browser.1.gz
                rm -f $out/share/man/man1/brave-browser{,-stable}.1.gz
                ln -s com.brave.Browser.1.gz $out/share/man/man1/brave.1.gz
              '';

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
