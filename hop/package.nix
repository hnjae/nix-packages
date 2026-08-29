{
  cargo-tauri,
  fetchFromGitHub,
  fetchPnpmDeps,
  glib-networking,
  jq,
  lib,
  nodejs,
  nix-update-script,
  openssl,
  pkg-config,
  pnpm_10,
  pnpmConfigHook,
  rustPlatform,
  stdenv,
  webkitgtk_4_1,
  wrapGAppsHook3,
}:
let
  appId = "net.golbin.hop";
  version = "0.4.4";

  src = fetchFromGitHub {
    owner = "golbin";
    repo = "hop";
    tag = "v${version}";
    hash = "sha256-CM56MNKuHtQ1YThOtc5n9tgXCfSfjNSzwRTayrGXw/Q=";
    fetchSubmodules = true;
  };

  pnpmDeps = fetchPnpmDeps {
    pname = "hop-studio-host";
    inherit version src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    hash = "sha256-QyRbMQwQD3cgkwHIr0K5kUSNHTshd70IZOVeCFVbW0A=";
  };

  frontend = stdenv.mkDerivation {
    pname = "hop-studio-host";
    inherit version src pnpmDeps;

    nativeBuildInputs = [
      nodejs
      pnpm_10
      pnpmConfigHook
    ];

    buildPhase = ''
      runHook preBuild
      pnpm run build:studio
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r apps/studio-host/dist "$out"
      runHook postInstall
    '';

    dontFixup = true;
  };
in
rustPlatform.buildRustPackage {
  pname = "hop";
  inherit version src;

  cargoRoot = "apps/desktop/src-tauri";
  buildAndTestSubdir = "apps/desktop/src-tauri";
  cargoHash = "sha256-9jSX0O7tRFdTeDvxEY9xae+iWE2N5HNgiNA9DkVbmLI=";

  nativeBuildInputs = [
    cargo-tauri.hook
    jq
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    glib-networking
    openssl
    webkitgtk_4_1
  ];

  doCheck = false;

  postInstall = ''
    mv "$out/bin/hop-desktop" "$out/bin/${appId}"

    mv "$out/share/applications/HOP.desktop" "$out/share/applications/${appId}.desktop"
    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-warn 'Exec=hop-desktop' 'Exec=${appId}' \
      --replace-warn 'Icon=hop-desktop' 'Icon=${appId}' \
      --replace-warn 'StartupWMClass=hop-desktop' 'StartupWMClass=${appId}'

    for size in 32x32 128x128 256x256 512x512; do
      mv "$out/share/icons/hicolor/$size/apps/hop-desktop.png" \
        "$out/share/icons/hicolor/$size/apps/${appId}.png"
    done
  '';

  postPatch = ''
    jq --arg dist "${frontend}" '
      del(.build.beforeBuildCommand, .build.beforeDevCommand)
      | .build.frontendDist = $dist
    ' apps/desktop/src-tauri/tauri.conf.json > tauri.conf.json.tmp
    mv tauri.conf.json.tmp apps/desktop/src-tauri/tauri.conf.json
  '';

  passthru = {
    inherit pnpmDeps;
    updateScript = nix-update-script {
      extraArgs = [ "--flake" ];
    };
  };

  meta = {
    description = "Open desktop editor for HWP and HWPX documents";
    homepage = "https://github.com/golbin/hop";
    license = lib.licenses.mit;
    mainProgram = appId;
    platforms = lib.platforms.linux;
  };
}
