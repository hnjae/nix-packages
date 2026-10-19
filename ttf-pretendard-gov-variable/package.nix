{
  fetchurl,
  lib,
  nix-update-script,
  stdenvNoCC,
}:
let
  version = "1.3.9";
  licenseFile = fetchurl {
    url = "https://raw.githubusercontent.com/orioncactus/pretendard/v${version}/LICENSE";
    hash = "sha256-0x3dnyvtMv1+MCogXPI4C6DeZSkVLSOe+Zz7byYb/AQ=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "ttf-pretendard-gov-variable";
  inherit version;

  src = fetchurl {
    url = "https://raw.githubusercontent.com/orioncactus/pretendard/v${version}/packages/pretendard-gov/dist/public/variable/PretendardGOVVariable.ttf";
    hash = "sha256-T9Q5HGmDRElqE9rbN5LjtMulkkJfOH5BzlnWj5BK6FQ=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 "$src" "$out/share/fonts/truetype/PretendardGOVVariable.ttf"
    install -Dm444 ${licenseFile} "$out/share/doc/ttf-pretendard-gov-variable/LICENSE"
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--url=https://github.com/orioncactus/pretendard"
      "--use-github-releases"
      "--version-regex=^v([0-9.]+)$"
    ];
  };

  meta = {
    description = "Pretendard GOV variable font for Korean public services";
    homepage = "https://github.com/orioncactus/pretendard";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
