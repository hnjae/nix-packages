{
  fetchurl,
  lib,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ttf-monoplex-cjk";
  version = "1.1.0";

  src = fetchurl {
    url = "https://github.com/y-kim/monoplex/releases/download/monoplex-cjk-${version}/MonoplexCJK_v${version}.zip";
    hash = "sha256-ugth7+ec+P605GKkSGs1uwBMVwYQZcejxow0Ndgi05U=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = "MonoplexCJK";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/truetype" MonoplexCJK-*.ttf
    install -Dm444 LICENSE.md "$out/share/doc/ttf-monoplex-cjk/LICENSE.md"
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--use-github-releases"
      "--version-regex=^monoplex-cjk-([0-9.]+)$"
    ];
  };

  meta = {
    description = "Monoplex CJK programming font";
    homepage = "https://github.com/y-kim/monoplex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
