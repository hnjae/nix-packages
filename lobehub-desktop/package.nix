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
  imagemagick,
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
  libxtst,
  libxrender,
  libxcb,
  ...
}:
let
  appId = "com.lobehub.lobehub-desktop";
  version = "2.2.15";
in
stdenv.mkDerivation {
  pname = "lobehub-desktop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/lobehub/lobehub/releases/download/v${version}/lobehub-desktop_${version}_amd64.deb";
    hash = "sha256-5wdnBFftwQcQRNIXe9iv225itJAfhi1xqLY4QjtiZC8=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    imagemagick
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
    mv "opt/LobeHub" "$out/lib/lobehub-desktop"

    install -m 444 -D "usr/share/applications/lobehub-desktop.desktop" \
      "$out/share/applications/${appId}.desktop"

    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-warn 'Exec=/opt/LobeHub/lobehub-desktop %U' 'Exec=${appId} %U' \
      --replace-warn 'Icon=lobehub-desktop' 'Icon=${appId}' \
      --replace-warn 'StartupWMClass=LobeHub' 'StartupWMClass=${appId}'

    iconDir="$out/share/icons/hicolor/512x512/apps"
    mkdir -p "$iconDir"
    magick "usr/share/icons/hicolor/514x514/apps/lobehub-desktop.png" \
      -resize 512x512 "$iconDir/${appId}.png"
    chmod 444 "$iconDir/${appId}.png"

    makeWrapper "$out/lib/lobehub-desktop/lobehub-desktop" "$out/bin/${appId}" \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --add-flags "--no-sandbox" \
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
    description = "Desktop version of LobeHub, an open-source modern design AI chat framework";
    homepage = "https://github.com/lobehub/lobehub";
    license = {
      fullName = "LobeHub Community License";
      url = "https://github.com/lobehub/lobehub/blob/main/LICENSE";
      free = false;
    };
    mainProgram = appId;
    platforms = [ "x86_64-linux" ];
  };
}
