{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  nix-update-script,
  ...
}:
let
  appId = "ai.opencode.desktop";
in
appimageTools.wrapType2 rec {
  pname = "opencode-desktop";
  version = "1.18.15";

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-x86_64.AppImage";
    hash = "sha256-lKJq9LBcc8T+HCOQkFolIi9Ces8frR9LWWJopYJ/hLg=";
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
      mv "$out/bin/${pname}" "$out/bin/${appId}"

      wrapProgram $out/bin/${appId} \
        --add-flags "--no-sandbox" \
        --add-flags "--class=${appId}" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-wayland-ime" \
        --add-flags "--wayland-text-input-version=3"

      shopt -s nullglob

      desktopFile=
      for candidate in ${contents}/*.desktop ${contents}/usr/share/applications/*.desktop; do
        if grep -Iq '^\[Desktop Entry\]' "$candidate"; then
          desktopFile="$candidate"
          break
        fi
      done

      if [ -z "$desktopFile" ]; then
        echo "ERR: No desktop entry found in extracted AppImage" >&2
        exit 1
      fi

      install -m 444 -D "$desktopFile" "$out/share/applications/${appId}.desktop"

      substituteInPlace "$out/share/applications/${appId}.desktop" \
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${appId} %U'

      for iconPath in ${contents}/usr/share/icons/hicolor/*x*/apps/*.png; do
        size="$(basename -- "$(dirname -- "$(dirname -- "$iconPath")")")"

        case "$size" in
          32x32|48x48|64x64|128x128|256x256)
            install -m 444 -D "$iconPath" "$out/share/icons/hicolor/$size/apps/${appId}.png"
            ;;
        esac
      done
    '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "AI-powered development tool desktop app";
    homepage = "https://github.com/anomalyco/opencode";
    license = lib.licenses.mit;
    mainProgram = appId;
    platforms = [ "x86_64-linux" ];
  };
}
