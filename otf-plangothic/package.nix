{
  _7zz,
  fetchurl,
  lib,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "otf-plangothic";
  version = "2.9.5795";

  src = fetchurl {
    url = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic_Project/releases/download/V${version}/Plangothic-OTF-V${version}.7z";
    hash = "sha256-WmyKlXygNIerhhV9xYgK+aTp8fobdLNpNIZAjZdf8fk=";
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

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--version-regex"
      "V(.*)"
    ];
  };

  meta = {
    description = "OpenType collection based on Source Han Sans CN with supplementary CJKV ideographs";
    homepage = "https://github.com/Fitzgerald-Porthmouth-Koenigsegg/Plangothic-Project";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
}
