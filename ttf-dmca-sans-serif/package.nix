{
  fetchzip,
  lib,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  pname = "ttf-dmca-sans-serif";
  version = "9.0-20252";

  src = fetchzip {
    url = "https://typedesign.replit.app/DMCAsansserif9.0-20252.zip";
    hash = "sha256-wygnkotk7CkFbUK/dct4wBt8/+M4IAtJ3YHtIsJzQHg=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -m444 -Dt "$out/share/fonts/truetype" DMCAsansserif-*.ttf
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "General purpose sans serif font metric-compatible with Microsoft Consolas";
    homepage = "https://typedesign.repl.co/dmcasansserif.html";
    license = lib.licenses.publicDomain;
    platforms = lib.platforms.all;
  };
}
