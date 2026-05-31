/*
  NOTE:
    - Release Notes: <https://cider.sh/changelogs>
    - To download binary: <https://taproom.cider.sh/about>
    - Purchased from: <https://cidercollective.itch.io/cider>
*/
{
  appimageTools,
  makeWrapper,
  requireFile,
  lib,
  ...
}:
appimageTools.wrapType2 rec {
  pname = "Cider";
  version = "3.1.8";

  src = requireFile {
    name = "cider-v${version}-linux-x64.AppImage";
    url = "https://taproom.cider.sh/downloads";
    # Run `nix-store --add-fixed sha256 <file>` to add a file to the /nix/store.
    # Run `nix hash file <file>` to get the checksum.
    sha256 = "sha256-s1CMYAfDULaEyO0jZguA2bA7D7ogqRR4v/LkMD+luKw=";
  };

  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands =
    let
      contents = appimageTools.extract {
        inherit version src pname;
      };
      icon = "${contents}/Cider.png";
    in
    ''
      wrapProgram $out/bin/${pname} \
        --add-flags "--no-sandbox" \
        --add-flags "--disable-gpu-sandbox" \
        --add-flags "--enable-features=WaylandWindowDecorations" \
        --add-flags "--enable-features=UseOzonePlatform" \
        --add-flags "--ozone-platform-hint=auto" \
        --add-flags "--enable-wayland-ime" \
        --add-flags "--wayland-text-input-version=3"

      install -m 444 -D ${contents}/Cider.desktop $out/share/applications/${pname}.desktop

      substituteInPlace "$out/share/applications/${pname}.desktop" \
        --replace-warn 'Icon=cider' 'Icon=${pname}'

      substituteInPlace "$out/share/applications/${pname}.desktop" \
        --replace-warn 'StartupWMClass=cider' 'StartupWMClass=${pname}'

      mkdir -p "$out/share/icons/hicolor/256x256/apps"

      cp --reflink=auto "${icon}" "$out/share/icons/hicolor/256x256/apps/${pname}.png"
    '';

  meta = {
    description = "A cross-platform Apple Music experience built on Vue.js and written from the ground up with performance in mind";
    homepage = "https://cider.sh";
    license = lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
