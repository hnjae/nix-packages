{
  cmake,
  fetchFromGitHub,
  kdePackages,
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation rec {
  pname = "kdecodexbar";
  version = "1.1.0";

  src = fetchFromGitHub {
    owner = "rursache";
    repo = "KDECodexBar";
    rev = "v${version}";
    hash = "sha256-z+HxmDm1iA1H8zVhJftrXw1mokNXKShr4LJRGmQgXdI=";
  };

  nativeBuildInputs = [
    cmake
    kdePackages.extra-cmake-modules
    kdePackages.wrapQtAppsHook
  ];

  buildInputs = with kdePackages; [
    kconfig
    kcoreaddons
    ki18n
    kstatusnotifieritem
    kwindowsystem
    qtbase
  ];

  cmakeFlags = [
    "-DAPP_VERSION=v${version}"
  ];

  postInstall = ''
    install -Dm444 "$src/LICENSE" "$out/share/licenses/${pname}/LICENSE"
  '';

  meta = {
    description = "AI usage tracker for KDE Plasma";
    homepage = "https://github.com/rursache/KDECodexBar";
    license = lib.licenses.mit;
    mainProgram = "kdecodexbar";
    platforms = lib.platforms.linux;
  };
}
