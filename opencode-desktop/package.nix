{
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  autoPatchelfHook,
  cairo,
  cups,
  dbus,
  dpkg,
  expat,
  fetchurl,
  gdk-pixbuf,
  glib,
  gtk3,
  lib,
  libdrm,
  libnotify,
  libsecret,
  libuuid,
  libxkbcommon,
  makeWrapper,
  mesa,
  nix-update-script,
  nspr,
  nss,
  pango,
  stdenv,
  udev,
  xdg-utils,
  libx11,
  libxscrnsaver,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxrandr,
  libxrender,
  libxtst,
  libxcb,
  ...
}:
let
  appId = "ai.opencode.desktop";
  version = "1.18.25";
in
stdenv.mkDerivation {
  pname = "opencode-desktop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-desktop-linux-amd64.deb";
    hash = "sha256-MZGYF5p/NWuWK1Km4YKb2tKGg65UlJXrXYSmpuLYISs=";
  };

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
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libnotify
    libsecret
    libuuid
    libxkbcommon
    mesa
    nspr
    nss
    pango
    udev
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
  ];

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;
  autoPatchelfIgnoreMissingDeps = [ "libc.musl-x86_64.so.1" ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"
    mv "opt/OpenCode" "$out/lib/opencode-desktop"

    install -m 444 -D "usr/share/applications/${appId}.desktop" \
      "$out/share/applications/${appId}.desktop"

    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-warn 'Exec=/opt/OpenCode/${appId} %U' 'Exec=${appId} %U' \
      --replace-warn 'NoDisplay=true' '''

    for iconPath in usr/share/icons/hicolor/*x*/apps/*.png; do
      size="$(basename -- "$(dirname -- "$(dirname -- "$iconPath")")")"
      install -m 444 -D "$iconPath" "$out/share/icons/hicolor/$size/apps/${appId}.png"
    done

    install -m 444 -D "usr/share/metainfo/${appId}.metainfo.xml" \
      "$out/share/metainfo/${appId}.metainfo.xml"

    makeWrapper "$out/lib/opencode-desktop/${appId}" "$out/bin/${appId}" \
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
