{
  fetchurl,
  lib,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ttf-monoplex-cjk-nerd-font";
  version = "1.1.0";

  src = fetchurl {
    url = "https://github.com/y-kim/monoplex/releases/download/monoplex-cjk-nerd-font-${version}/MonoplexCJKNerdFont_v${version}.zip";
    hash = "sha256-d7IKlQ6RJwe5ooCU1PuFn00IMrE5qiiY0kh/53vuX4U=";
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

  meta = {
    description = "Nerd Fonts patched Monoplex CJK programming font";
    homepage = "https://github.com/y-kim/monoplex";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
