{
  copyDesktopItems,
  fetchFromGitHub,
  lib,
  makeDesktopItem,
  nix-update-script,
  qt6,
  stdenv,
}:
let
  version = "0.66.0";
  appId = "com.steipete.CodexBar";
  src = fetchFromGitHub {
    owner = "steipete";
    repo = "CodexBar";
    tag = "v${version}";
    hash = "sha256-CbgHRkNTASLtMBplAtq9V1XVKy/12N9sHIzmV9X8QHQ=";
  };

  # Mirrors the launcher upstream install.py writes. Exec resolves through
  # PATH so the entry survives store-path changes; the app id is explicit in
  # the binary (setDesktopFileName), not derived from argv[0].
  desktopItem = makeDesktopItem {
    name = appId;
    desktopName = "CodexBar";
    comment = "AI usage, accounts and local spending";
    exec = "${appId} --usage";
    icon = appId;
    categories = [
      "Utility"
      "Development"
    ];
    startupWMClass = appId;
    actions = {
      Settings = {
        name = "Settings";
        exec = "${appId} --settings";
      };
      Spending = {
        name = "Usage & Spend";
        exec = "${appId} --spending";
      };
    };
  };
in
stdenv.mkDerivation {
  pname = "codexbar-desktop";
  inherit version src;

  # qmake must run in the .pro directory: desktop.qrc and SOURCES use paths
  # relative to it.
  sourceRoot = "${src.name}/Integrations/Linux";

  nativeBuildInputs = [
    copyDesktopItems
    qt6.qmake
    qt6.wrapQtAppsHook
  ];

  desktopItems = [ desktopItem ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    qt6.qtwayland
  ];

  env.CODEXBAR_DESKTOP_VERSION = version;

  # Coherent identity: binary, icon, launcher entry, and StartupWMClass (the
  # app's real window class) all share the app id. Patched rather than passed
  # as a qmake assignment because the .pro reassigns TARGET.
  postPatch = ''
    substituteInPlace codexbar-linux.pro \
      --replace-fail 'TARGET = codexbar-linux' 'TARGET = ${appId}'
  '';

  postInstall = ''
    install -Dm644 icon.svg \
      $out/share/icons/hicolor/scalable/apps/${appId}.svg
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "Qt 6 desktop app showing AI coding provider usage, spending and settings";
    homepage = "https://github.com/steipete/CodexBar";
    changelog = "https://github.com/steipete/CodexBar/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "com.steipete.CodexBar";
    platforms = lib.platforms.linux;
  };
}
