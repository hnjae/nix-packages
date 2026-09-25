{
  fetchurl,
  lib,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:
let
  version = "1.8";
  licenseFile = fetchurl {
    url = "https://raw.githubusercontent.com/jhaemin/Interop/v${version}/LICENSE";
    hash = "sha256-p1Lo55uaEiOWi0SOjm7WG6+ut+D02ftvDEDTXnK6Nzs=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "otf-interop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/jhaemin/Interop/releases/download/v${version}/Interop-${version}.zip";
    hash = "sha256-KoDRtNDM/IOuNjQL4y+CldfmMSXdKuRSCoFwkt1FA2w=";
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = "Interop-${version}";
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/opentype
    cp otf/*.otf $out/share/fonts/opentype/
    install -Dm644 ${licenseFile} $out/share/doc/otf-interop/LICENSE
    runHook postInstall
  '';
  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "Interop font family combining Inter and Noto Sans KR";
    homepage = "https://github.com/jhaemin/Interop";
    license = lib.licenses.ofl;
  };
}
