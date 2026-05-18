{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  supportedSystems,
  ...
}:
appimageTools.wrapType2 rec {
  pname = "opencode-desktop";
  version = "1.4.1";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-electron-linux-x86_64.AppImage";
    hash = "sha256-FyRJXCkrClqTqspxI73paHlK+bMVSDLV10WSxLmMElk=";
  };

  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands =
    let
      contents = appimageTools.extract {
        inherit version src pname;
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

      shopt -s nullglob

      desktopFiles=(
        ${contents}/*.desktop
        ${contents}/usr/share/applications/*.desktop
      )

      if [ "''${#desktopFiles[@]}" -eq 0 ]; then
        echo "ERR: No desktop entry found in extracted AppImage" >&2
        exit 1
      fi

      install -m 444 -D "''${desktopFiles[0]}" "$out/share/applications/${pname}.desktop"

      substituteInPlace "$out/share/applications/${pname}.desktop" \
        --replace-warn 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U' \
        --replace-warn 'Exec=AppRun %U' 'Exec=${pname} %U' \
        --replace-warn 'Exec=AppRun --no-sandbox' 'Exec=${pname}' \
        --replace-warn 'Exec=AppRun' 'Exec=${pname}' \
        --replace-warn 'Icon=@opencode-aidesktop-electron' 'Icon=${pname}' \
        --replace-warn 'Icon=OpenCode' 'Icon=${pname}' \
        --replace-warn 'Icon=opencode-electron' 'Icon=${pname}' \
        --replace-warn 'Icon=opencode-desktop-desktop' 'Icon=${pname}' \
        --replace-warn 'StartupWMClass=OpenCode' 'StartupWMClass=${pname}' \
        --replace-warn 'StartupWMClass=opencode-electron' 'StartupWMClass=${pname}' \
        --replace-warn 'StartupWMClass=opencode-desktop-desktop' 'StartupWMClass=${pname}'

      for iconPath in ${contents}/usr/share/icons/hicolor/*x*/apps/*.png; do
        size="$(basename -- "$(dirname -- "$(dirname -- "$iconPath")")")"

        case "$size" in
          32x32|48x48|64x64|128x128|256x256)
            install -m 444 -D "$iconPath" "$out/share/icons/hicolor/$size/apps/${pname}.png"
            ;;
        esac
      done
    '';

  meta = {
    description = "AI-powered development tool desktop app";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    mainProgram = pname;
    platforms = supportedSystems;
  };
}
