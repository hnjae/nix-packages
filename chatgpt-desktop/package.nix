{
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  curl,
  cups,
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
  libusb1,
  makeWrapper,
  mesa,
  nspr,
  nss,
  pango,
  stdenv,
  udev,
  writeShellScript,
  xdg-utils,
}:
let
  appId = "com.openai.ChatGPT";
  pname = "chatgpt-desktop";
  version = "26.825.51511";

  sources = {
    amd64 = {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_amd64.deb";
      hash = "sha256-NVSwAixs+1EzJvQ/0R9xiDWncIasTXyi/z67ui1Mf0U=";
    };
    arm64 = {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${version}_arm64.deb";
      hash = "sha256-El42Ui1Dx1vXlYR3hGumsc3fLrGc78tX3agL4XQvkX8=";
    };
  };

  debArch =
    {
      x86_64-linux = "amd64";
      aarch64-linux = "arm64";
    }
    .${stdenv.hostPlatform.system} or (throw "${pname} supports x86_64-linux and aarch64-linux only");

in
stdenv.mkDerivation (finalAttrs: {
  pname = "chatgpt-desktop";
  inherit version;

  src = fetchurl sources.${debArch};

  nativeBuildInputs = [
    autoPatchelfHook
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
    libusb1
    libxkbcommon
    mesa
    nspr
    nss
    pango
    udev
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"
    mv "usr/lib/chatgpt" "$out/lib/chatgpt"

    if [ ! -f "$out/lib/chatgpt/ChatGPT" ]; then
      echo "ERR: expected ELF entrypoint missing from deb: usr/lib/chatgpt/ChatGPT" >&2
      exit 1
    fi

    install -m 444 -D "usr/share/applications/chatgpt.desktop" \
      "$out/share/applications/${appId}.desktop"

    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-warn 'Exec=chatgpt %U' 'Exec=${appId} %U' \
      --replace-warn 'Icon=chatgpt' 'Icon=${appId}'
    printf '\nStartupWMClass=${appId}\n' >> "$out/share/applications/${appId}.desktop"

    install -m 444 -D "usr/share/pixmaps/chatgpt.png" \
      "$out/share/icons/hicolor/1024x1024/apps/${appId}.png"
    install -m 444 -D "usr/share/pixmaps/chatgpt.png" \
      "$out/share/pixmaps/${appId}.png"

    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/${appId}" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --add-flags "--no-sandbox" \
      --add-flags "--class=${appId}" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--wayland-text-input-version=3"

    runHook postInstall
  '';

  passthru.updateScript = writeShellScript "update-chatgpt-desktop" ''
    set -euo pipefail

    attr="''${1:-''${UPDATE_NIX_ATTR_PATH:-chatgpt-desktop}}"
    packageFile="./$attr/package.nix"

    currentVersion="$(
      sed -n 's/^  version = "\([^"]*\)";$/\1/p' "$packageFile" | head -n 1
    )"
    if [ -z "$currentVersion" ]; then
      echo "ERR: could not read current version from $packageFile" >&2
      exit 1
    fi

    latestVersion=""
    declare -A sourceSha256s=()
    for debArch in amd64 arm64; do
      index="$(
        curl -fsSL https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-''${debArch}/Packages
      )"

      archLatestVersion="$(
        printf '%s\n' "$index" \
          | awk 'BEGIN { RS = ""; FS = "\n" } /(^|\n)Architecture: '"$debArch"'(\n|$)/ { for (i = 1; i <= NF; i++) if ($i ~ /^Version:/) { sub(/^Version: /, "", $i); print $i } }' \
          | sort -V | tail -n 1
      )"
      if [ -z "$archLatestVersion" ]; then
        echo "ERR: no version found in $debArch apt package index" >&2
        exit 1
      fi

      if [ -z "$latestVersion" ]; then
        latestVersion="$archLatestVersion"
      elif [ "$latestVersion" != "$archLatestVersion" ]; then
        echo "ERR: version mismatch between architectures: $latestVersion != $archLatestVersion ($debArch)" >&2
        exit 1
      fi

      sourceSha256="$(
        printf '%s\n' "$index" \
          | awk -v arch="$debArch" 'BEGIN { RS = ""; FS = "\n" } { hit = 0; for (i = 1; i <= NF; i++) { if ($i ~ "^Filename: pool/main/c/chatgpt/chatgpt_[^/]*_" arch ".deb$") hit = 1; else if ($i ~ /^SHA256:/ && hit) { sub(/^SHA256: /, "", $i); print $i } } }'
      )"
      if [ -z "$sourceSha256" ]; then
        echo "ERR: no SHA256 found in $debArch apt package index for $archLatestVersion" >&2
        exit 1
      fi
      sourceSha256s["$debArch"]="$sourceSha256"
    done

    echo "chatgpt-desktop: current=$currentVersion latest=$latestVersion"

    if [ "$currentVersion" = "$latestVersion" ]; then
      echo "no update available"
      exit 0
    fi

    if [ "$(grep -c 'version = "'"$currentVersion"'";' "$packageFile")" -ne 1 ]; then
      echo "ERR: expected exactly one version assignment in $packageFile" >&2
      exit 1
    fi

    sed -i 's|version = "'"$currentVersion"'";|version = "'"$latestVersion"'";|' "$packageFile"

    for debArch in amd64 arm64; do
      newHash="$(nix hash convert --hash-algo sha256 --to sri "''${sourceSha256s[$debArch]}")"
      if [ -z "$newHash" ] || [ "$newHash" = "null" ]; then
        echo "ERR: failed to convert hash for $debArch $latestVersion" >&2
        exit 1
      fi

      oldHash="$(sed -n "/^    ''${debArch} = {/,/};/s/^      hash = \"\(sha256-[^\"]*\)\";$/\1/p" "$packageFile")"
      if [ -z "$oldHash" ]; then
        echo "ERR: could not read current hash for $debArch from $packageFile" >&2
        exit 1
      fi

      if [ "$(grep -c 'hash = "'"$oldHash"'";' "$packageFile")" -ne 1 ]; then
        echo "ERR: expected exactly one hash assignment for $debArch in $packageFile" >&2
        exit 1
      fi

      sed -i 's|hash = "'"$oldHash"'";|hash = "'"$newHash"'";|' "$packageFile"
      echo "updated chatgpt-desktop ($debArch) hash: $oldHash -> $newHash"
    done

    echo "updated chatgpt-desktop: $currentVersion -> $latestVersion"
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux";
    homepage = "https://developers.openai.com/codex/app";
    license = lib.licenses.unfree;
    mainProgram = appId;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
