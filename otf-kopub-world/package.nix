{
  fetchzip,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "otf-kopub-world";
  version = "2.0";

  src = fetchzip {
    url = "https://www.kopus.org/wp-content/uploads/2022/04/KOPUB2.0_OTF_FONTS.zip";
    hash = "sha256-PInBRATZ4JSAN9I8a1WyLPXNsQi9LrmvSM8py1WTnBI=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/opentype" *.otf
    runHook postInstall
  '';

  meta = {
    description = "Digital screen-friendly Korean KoPub fonts";
    homepage = "http://www.kopus.org/biz-electronic-font2/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
