{
  fetchurl,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "otf-ridibatang";
  version = "1.0.1";

  src = fetchurl {
    url = "https://ridicorp.com/wp-content/themes/ridicorp/css/font/RIDIBatang.otf";
    hash = "sha256-8TpJwIFdJUrBXjkpU6CwVmE97AjOs3jlTu7RTE/amlQ=";
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm444 "$src" "$out/share/fonts/opentype/RIDIBatang.otf"
    runHook postInstall
  '';

  meta = {
    description = "RIDI Batang font for readable long-form e-books";
    homepage = "https://ridicorp.com/ridibatang/";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
