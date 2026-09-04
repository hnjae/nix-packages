{
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  cups,
  curl,
  dbus,
  dpkg,
  expat,
  fetchurl,
  glib,
  gtk3,
  lib,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libxkbcommon,
  libXrandr,
  libcap_ng,
  libseccomp,
  makeWrapper,
  mesa,
  nspr,
  nss,
  pango,
  stdenv,
  udev,
  writeShellScript,
}:
let
  appId = "com.anthropic.Claude";
  version = "1.46388.2";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  inherit version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${version}_amd64.deb";
    hash = "sha256-mL9U6F5JFgaMQoFFmw8EMdj/aANHc/PumDEdcgZWarE=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    curl
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxkbcommon
    libcap_ng
    libseccomp
    mesa
    nspr
    nss
    pango
    udev
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    extracted="deb-extracted"
    mkdir "$extracted"
    dpkg-deb --fsys-tarfile $src | tar -x -C "$extracted" \
      --no-same-owner --no-same-permissions

    mkdir -p "$out/bin" "$out/share"

    cp -r "$extracted/usr/lib" "$out/lib"
    cp -r \
      "$extracted/usr/share/applications" \
      "$extracted/usr/share/icons" \
      "$out/share/"

    rm -f "$extracted/usr/bin/claude-desktop"

    for elf in "$out"/lib/${finalAttrs.pname}/${finalAttrs.pname} \
      "$out"/lib/${finalAttrs.pname}/chrome_crashpad_handler \
      "$out"/lib/${finalAttrs.pname}/chrome-sandbox; do
      if [ ! -f "$elf" ]; then
        echo "ERR: expected ELF entrypoint missing from deb: $elf" >&2
        exit 1
      fi
    done

    makeWrapper "$out/lib/${finalAttrs.pname}/${finalAttrs.pname}" "$out/bin/${appId}" \
      --add-flags "--no-sandbox" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--wayland-text-input-version=3"

    desktopFile="$(find "$out/share/applications" -maxdepth 1 -name '*.desktop' -print -quit)"
    if [ -z "$desktopFile" ]; then
      echo "ERR: No desktop entry found in deb contents" >&2
      exit 1
    fi

    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-warn 'Exec=claude-desktop' 'Exec=${appId}' \
      --replace-warn 'Icon=claude-desktop' 'Icon=${appId}'

    for dir in "$out"/share/icons/hicolor/*/apps; do
      if [ -f "$dir/claude-desktop.png" ]; then
        mv "$dir/claude-desktop.png" "$dir/${appId}.png"
      fi
    done

    runHook postInstall
  '';

  passthru.updateScript = writeShellScript "update-claude-desktop" ''
    set -euo pipefail

    attr="''${1:-''${UPDATE_NIX_ATTR_PATH:-claude-desktop}}"
    packageFile="./$attr/package.nix"

    index="$(
      curl -fsSL https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages
    )"

    latestVersion="$(
      printf '%s\n' "$index" \
        | awk 'BEGIN { RS = ""; FS = "\n" } /(^|\n)Architecture: amd64(\n|$)/ { for (i = 1; i <= NF; i++) if ($i ~ /^Version:/) { sub(/^Version: /, "", $i); print $i } }' \
        | sort -V | tail -n 1
    )"
    if [ -z "$latestVersion" ]; then
      echo "ERR: no version found in apt package index" >&2
      exit 1
    fi

    currentVersion="$(
      sed -n 's/^  version = "\([^"]*\)";$/\1/p' "$packageFile" | head -n 1
    )"
    if [ -z "$currentVersion" ]; then
      echo "ERR: could not read current version from $packageFile" >&2
      exit 1
    fi

    echo "claude-desktop: current=$currentVersion latest=$latestVersion"

    if [ "$currentVersion" = "$latestVersion" ]; then
      echo "no update available"
      exit 0
    fi

    sourceSha256="$(
      printf '%s\n' "$index" \
        | awk 'BEGIN { RS = ""; FS = "\n" } { hit = 0; for (i = 1; i <= NF; i++) { if ($i == "Filename: pool/main/c/claude-desktop/claude-desktop_'"$latestVersion"'_amd64.deb") hit = 1; else if ($i ~ /^SHA256:/ && hit) { sub(/^SHA256: /, "", $i); print $i } } }'
    )"
    if [ -z "$sourceSha256" ]; then
      echo "ERR: no SHA256 found in apt package index for $latestVersion" >&2
      exit 1
    fi

    newHash="$(nix hash convert --hash-algo sha256 --to sri "$sourceSha256")"
    if [ -z "$newHash" ] || [ "$newHash" = "null" ]; then
      echo "ERR: failed to convert hash for $latestVersion" >&2
      exit 1
    fi

    if [ "$(grep -c 'version = "'"$currentVersion"'";' "$packageFile")" -ne 1 ]; then
      echo "ERR: expected exactly one version assignment in $packageFile" >&2
      exit 1
    fi

    oldHash="$(sed -n 's/^.*hash = "\(sha256-[^"]*\)";$/\1/p' "$packageFile" | head -n 1)"
    if [ "$(grep -c 'hash = "'"$oldHash"'";' "$packageFile")" -ne 1 ]; then
      echo "ERR: expected exactly one hash assignment in $packageFile" >&2
      exit 1
    fi

    sed -i \
      -e 's|version = "'"$currentVersion"'";|version = "'"$latestVersion"'";|' \
      -e 's|hash = "'"$oldHash"'";|hash = "'"$newHash"'";|' \
      "$packageFile"

    echo "updated claude-desktop: $currentVersion -> $latestVersion ($newHash)"
  '';

  meta = {
    description = "Official Claude Desktop app for Linux";
    homepage = "https://claude.com/download";
    license = lib.licenses.unfree;
    mainProgram = appId;
    platforms = [ "x86_64-linux" ];
  };
})
