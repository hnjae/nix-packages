{
  fetchzip,
  lib,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ttf-freesentation";
  version = "2.001";

  src = fetchzip {
    url = "https://github.com/Freesentation/freesentation/archive/refs/tags/v${version}.zip";
    hash = "sha256-SbMNG2ITLZ0E6vHPGb7pH+AgTB4mv5wSwp8HSW2WzIU=";
    stripRoot = false;
  };

  nativeBuildInputs = [ unzip ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    unzip freesentation-${version}/Freesentation-${version}.zip
    install -m444 -Dt "$out/share/fonts/truetype" Freesentation-*.ttf
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "Korean font family designed for presentations";
    homepage = "https://freesentation.blog/";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
