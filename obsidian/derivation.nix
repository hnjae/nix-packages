{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  supportedSystems,
  ...
}:
appimageTools.wrapType2 rec {
  pname = "obsidian";
  version = "1.12.7";

  src = fetchurl {
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage";
    hash = "sha256-9ti5b+aFqGMsgZzAk6JIrOD2urQQ9EpskpomEbHrsXw=";
  };

  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands =
    let
      contents = appimageTools.extract {
        inherit version src pname;
      };
    in
    ''
      wrapProgram $out/bin/${pname} \
        --set LC_ALL en_IE.UTF-8 \
        --add-flags "--no-sandbox" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-wayland-ime" \
        --add-flags "--wayland-text-input-version=3"


      install -m 444 -D ${contents}/obsidian.desktop $out/share/applications/${pname}.desktop

      substituteInPlace "$out/share/applications/${pname}.desktop" \
        --replace-warn 'Exec=AppRun --no-sandbox %U' 'Exec=${pname} %U'

      ${lib.concatMapStrings
        (size: ''
          mkdir -p "$out/share/icons/hicolor/${size}x${size}/apps"
          cp --reflink=auto "${contents}/usr/share/icons/hicolor/${size}x${size}/apps/obsidian.png" \
            "$out/share/icons/hicolor/${size}x${size}/apps/${pname}.png"
        '')
        [
          "16"
          "32"
          "48"
          "64"
          "128"
          "256"
          "512"
        ]
      }
    '';

  meta = {
    description = "A powerful knowledge base that works on top of a local folder of plain text Markdown files";
    homepage = "https://obsidian.md";
    license = lib.licenses.obsidian;
    mainProgram = pname;
    platforms = supportedSystems;
  };
}
