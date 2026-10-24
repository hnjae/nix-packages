{
  fetchzip,
  lib,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "otf-kopub-world";
  version = "2026";

  src = fetchzip {
    url = "https://www.kopus.org/wp-content/uploads/2026/04/KOPUBWORLD_OTF_FONTS2026.zip";
    hash = "sha256-5IeEJSsH5FlvAIb0I+zn9Z3Ng6eIeqKIu+555jMc+D0=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/opentype" *.otf
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "Digital screen-friendly Korean KoPubWorld fonts";
    homepage = "https://www.kopus.org/biz-electronic-font/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.all;
  };
}
