{
  appimageTools,
  fetchurl,
  imagemagick,
  makeWrapper,
  nix-update-script,
  ...
}:
appimageTools.wrapType2 rec {
  pname = "lobehub-desktop";
  version = "2.2.14";

  src = fetchurl {
    url = "https://github.com/lobehub/lobehub/releases/download/v${version}/LobeHub-${version}.AppImage";
    hash = "sha256-aIeQa2I9OcBrOo2Dwuxeq+DQE/xmabw1/fXu1DgFq24=";
  };

  nativeBuildInputs = [
    imagemagick
    makeWrapper
  ];
  extraInstallCommands =
    let
      appId = "lobehub";
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
        --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U' \
        --replace-fail 'Icon=${pname}' 'Icon=${appId}' \
        --replace-fail 'StartupWMClass=LobeHub' 'StartupWMClass=${appId}'

      iconDir="$out/share/icons/hicolor/512x512/apps"
      mkdir -p "$iconDir"
      magick "${contents}/usr/share/icons/hicolor/514x514/apps/${pname}.png" \
        -resize 512x512 "$iconDir/${appId}.png"
      chmod 444 "$iconDir/${appId}.png"
    '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "Desktop version of LobeHub, an open-source modern design AI chat framework";
    homepage = "https://github.com/lobehub/lobehub";
    license = {
      fullName = "LobeHub Community License";
      url = "https://github.com/lobehub/lobehub/blob/main/LICENSE";
      free = false;
    };
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
