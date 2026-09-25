{
  lib,
  requireFile,
  stdenvNoCC,
  unzip,
}:
stdenvNoCC.mkDerivation {
  pname = "ttf-hcr";
  version = "2.120-20170407";

  src = requireFile {
    name = "HancomFont.zip";
    url = "https://www.hancom.com/support/downloadCenter/download";
    sha256 = "0725dicma6ing99b8ahyifi61avn2bb12rdxf8j3mrfw3bx5wxla";
  };

  sourceRoot = ".";
  nativeBuildInputs = [ unzip ];
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/truetype" *.ttf
    runHook postInstall
  '';

  meta = {
    description = "Hancom Office typeface family available for free use";
    homepage = "https://www.hancom.com/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
