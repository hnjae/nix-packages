{
  fetchzip,
  lib,
  nix-update-script,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ttf-sarasa-fixed-k-nerd-font";
  version = "1.0.40-0";

  src = fetchzip {
    url = "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts/releases/download/v${version}/sarasa-fixed-k-nerd-font.zip";
    hash = "sha256-qY7gVL3SLrfANeOScKzgopslOYpMnTdvOLlQPW0Qg0I=";
    stripRoot = false;
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    find . -type f -name '*.ttf' -exec install -m444 -Dt "$out/share/fonts/truetype" {} +
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--flake"
      "--use-github-releases"
    ];
  };

  meta = {
    description = "Nerd Fonts patched Sarasa Fixed K";
    homepage = "https://github.com/jonz94/Sarasa-Gothic-Nerd-Fonts";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
