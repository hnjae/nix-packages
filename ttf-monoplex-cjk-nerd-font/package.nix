{
  fetchurl,
  lib,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ttf-monoplex-cjk-nerd-font";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/y-kim/monoplex/releases/download/monoplex-cjk-nerd-font-${version}/MonoplexCJKNerdFont_v${version}.zip";
    hash = "sha256-NvVjzgpGr7lIK9LnoXP12NwscnMPWSUPKT3v1EymXW8=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = "MonoplexCJKNerdFont";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/truetype" MonoplexCJKNerdFont-*.ttf
    install -Dm444 LICENSE.md "$out/share/doc/ttf-monoplex-cjk-nerd-font/LICENSE.md"
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--use-github-releases"
      "--version-regex=^monoplex-cjk-nerd-font-([0-9.]+)$"
    ];
  };

  meta = {
    description = "Nerd Fonts patched Monoplex CJK programming font";
    homepage = "https://github.com/y-kim/monoplex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
