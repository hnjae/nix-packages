{
  _7zz,
  fetchurl,
  lib,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "otf-plangothic";
  version = "2.9.5792";

  src = fetchurl {
    url = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/download/V${version}/Plangothic-OTF-V${version}.7z";
    hash = "sha256-3/TKm7tkLEys4e0lvyJEY71tzPGxl7zFqg+xXKxg53Y=";
  };

  nativeBuildInputs = [ _7zz ];
  sourceRoot = "Plangothic-OTF-V${version}";
  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    7zz x -- $src >/dev/null
  '';

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/opentype" Plangothic.ttc
    runHook postInstall
  '';

  meta = {
    description = "OpenType collection based on Source Han Sans CN with supplementary CJKV ideographs";
    homepage = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic-Project";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
