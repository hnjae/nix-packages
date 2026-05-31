{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  ...
}:
let
  wrapperVersion = "1.3.27";
  claudeVersion = "1.1348.0";
in
appimageTools.wrapType2 rec {
  pname = "claude-desktop";
  version = "${wrapperVersion}+claude${claudeVersion}";

  src = fetchurl {
    url = "https://github.com/aaddrick/claude-desktop-debian/releases/download/v${wrapperVersion}%2Bclaude${claudeVersion}/${pname}-${claudeVersion}-${wrapperVersion}-amd64.AppImage";
    hash = "sha256-dGxnuDgtnPySk5iu1poPlaKtuVO1r4QgU4QBFlkSrxg=";
  };

  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands =
    let
      contents = appimageTools.extract {
        inherit pname src version;
      };
    in
    # bash
    ''
      wrapProgram $out/bin/${pname} \
        --add-flags "--no-sandbox" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-wayland-ime" \
        --add-flags "--wayland-text-input-version=3"

      desktopFile="$(find ${contents} -maxdepth 1 -name '*.desktop' -print -quit)"
      if [ -z "$desktopFile" ]; then
        echo "ERR: No desktop file found in AppImage contents" >&2
        exit 1
      fi

      install -m 444 -D "$desktopFile" "$out/share/applications/${pname}.desktop"

      sed -i \
        -e 's|^Exec=.*|Exec=${pname} %U|' \
        -e 's|^TryExec=.*|TryExec=${pname}|' \
        -e 's|^Icon=.*|Icon=${pname}|' \
        "$out/share/applications/${pname}.desktop"

      shopt -s nullglob

      for icon in ${contents}/usr/share/icons/hicolor/*/apps/*; do
        [ -f "$icon" ] || continue

        size="$(basename -- "$(dirname -- "$(dirname -- "$icon")")")"
        extension="''${icon##*.}"

        install -m 444 -D "$icon" \
          "$out/share/icons/hicolor/$size/apps/${pname}.$extension"
      done
    '';

  meta = {
    description = "Claude Desktop Linux package repackaged from the claude-desktop-debian AppImage release";
    homepage = "https://github.com/aaddrick/claude-desktop-debian";
    license = lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
