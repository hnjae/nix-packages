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
  libXScrnSaver,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libXtst,
  libcap_ng,
  libnotify,
  libsecret,
  libseccomp,
  libuuid,
  libxkbcommon,
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
  appId = "zcode";
  version = "3.10.1";

  sources = {
    "x86_64-linux" = {
      arch = "x64";
      hash = "sha256-HezuwB4FRaTH+OJlFiabHoRd/DUkWYsWVeOLxhrL8Is=";
    };
    "aarch64-linux" = {
      arch = "arm64";
      hash = "sha256-Irebq+OwD7b7/PfcwDO3VkpzT1PfTyiZjBhVYHEoayw=";
    };
  };

  source = sources.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "zcode";
  inherit version;

  src = fetchurl {
    url = "https://cdn-zcode.z.ai/zcode/electron/releases/${finalAttrs.version}/linux-${source.arch}/ZCode-${finalAttrs.version}-linux-${source.arch}.deb";
    inherit (source) hash;
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
    libXScrnSaver
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXtst
    libcap_ng
    libnotify
    libsecret
    libseccomp
    libuuid
    libxkbcommon
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

    mkdir -p "$out/bin" "$out/opt" "$out/share"

    cp -r "$extracted/opt/ZCode" "$out/opt/ZCode"
    cp -r \
      "$extracted/usr/share/applications" \
      "$extracted/usr/share/icons" \
      "$out/share/"

    for elf in "$out"/opt/ZCode/zcode \
      "$out"/opt/ZCode/chrome_crashpad_handler \
      "$out"/opt/ZCode/chrome-sandbox; do
      if [ ! -f "$elf" ]; then
        echo "ERR: expected ELF entrypoint missing from deb: $elf" >&2
        exit 1
      fi
    done

    makeWrapper "$out/opt/ZCode/zcode" "$out/bin/${appId}" \
      --add-flags "--no-sandbox" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--wayland-text-input-version=3"

    desktopFile="$out/share/applications/${appId}.desktop"
    if [ ! -f "$desktopFile" ]; then
      echo "ERR: No desktop entry found in deb contents" >&2
      exit 1
    fi

    substituteInPlace "$desktopFile" \
      --replace-warn 'Exec=/opt/ZCode/zcode %U' 'Exec=${appId} %U' \
      --replace-warn 'StartupWMClass=ZCode' 'StartupWMClass=${appId}'

    runHook postInstall
  '';

  passthru.updateScript = writeShellScript "update-zcode" ''
    set -euo pipefail

    attr="''${1:-''${UPDATE_NIX_ATTR_PATH:-zcode}}"
    packageFile="./$attr/package.nix"

    latestVersion="$(
      curl -fsSL https://zcode.z.ai/en \
        | grep -oP 'releases/\K[0-9]+\.[0-9]+\.[0-9]+(?=/linux-x64/)' \
        | sort -V | tail -n 1
    )"
    if [ -z "$latestVersion" ]; then
      echo "ERR: no version found on the ZCode homepage" >&2
      exit 1
    fi

    currentVersion="$(
      sed -n 's/^  version = "\([^"]*\)";$/\1/p' "$packageFile" | head -n 1
    )"
    if [ -z "$currentVersion" ]; then
      echo "ERR: could not read current version from $packageFile" >&2
      exit 1
    fi

    echo "zcode: current=$currentVersion latest=$latestVersion"

    if [ "$currentVersion" = "$latestVersion" ]; then
      echo "no update available"
      exit 0
    fi

    if [ "$(grep -c 'version = "'"$currentVersion"'";' "$packageFile")" -ne 1 ]; then
      echo "ERR: expected exactly one version assignment in $packageFile" >&2
      exit 1
    fi

    for arch in x64 arm64; do
      url="https://cdn-zcode.z.ai/zcode/electron/releases/$latestVersion/linux-$arch/ZCode-$latestVersion-linux-$arch.deb"
      newHash="$(
        nix store prefetch-file --json --hash-type sha256 "$url" \
          | sed -n 's/.*"hash":"\([^"]*\)".*/\1/p'
      )"
      if [ -z "$newHash" ] || [ "$newHash" = "null" ]; then
        echo "ERR: failed to prefetch hash for $latestVersion ($arch)" >&2
        exit 1
      fi

      oldHash="$(
        awk -v archLine="arch = \"$arch\";" '
          index($0, archLine) { seen = 1; next }
          seen && match($0, /sha256-[^"]*/) { print substr($0, RSTART, RLENGTH); exit }
        ' "$packageFile"
      )"
      if [ -z "$oldHash" ]; then
        echo "ERR: could not read current hash for $arch from $packageFile" >&2
        exit 1
      fi
      if [ "$(grep -cF "$oldHash" "$packageFile")" -ne 1 ]; then
        echo "ERR: expected exactly one occurrence of the $arch hash in $packageFile" >&2
        exit 1
      fi

      sed -i "s|$oldHash|$newHash|" "$packageFile"
      echo "zcode($arch): $oldHash -> $newHash"
    done

    sed -i \
      -e 's|version = "'"$currentVersion"'";|version = "'"$latestVersion"'";|' \
      "$packageFile"

    echo "updated zcode: $currentVersion -> $latestVersion"
  '';

  meta = {
    description = "Desktop app for agentic coding with GLM models";
    homepage = "https://zcode.z.ai";
    license = lib.licenses.unfree;
    mainProgram = appId;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
