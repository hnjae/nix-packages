{
  fetchurl,
  lib,
  nix-update-script,
  stdenv,
}:
let
  version = "0.60.4";

  src = fetchurl {
    url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-musl-${stdenv.hostPlatform.uname.processor}.tar.gz";
    hash =
      if stdenv.hostPlatform.isAarch64 then
        "sha256-oygcik7RgPY9axV77TMNKOS6bMn1riLHLK9PLAkRGwI="
      else
        "sha256-8GKyba26KW1QhhQDns/h5IAo3P7mQhp4pH7MuiHsPpE=";
  };
in
stdenv.mkDerivation {
  pname = "codexbar-cli";
  inherit version src;

  # The archive has no top-level directory and the first entry is the
  # provider-plugin bundle; keep the working dir at the unpack root.
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    # The CLI resolves VERSION and its provider-plugin bundle relative to the
    # real executable, so they must stay beside it; bin/codexbar is a symlink.
    mkdir -p $out/lib/codexbar $out/bin
    install -Dm755 CodexBarCLI $out/lib/codexbar/CodexBarCLI
    install -Dm644 VERSION $out/lib/codexbar/VERSION
    cp -r CodexBar_CodexBarCore.bundle $out/lib/codexbar/
    ln -s ../lib/codexbar/CodexBarCLI $out/bin/codexbar
    runHook postInstall
  '';

  # Runs after fixup, so this validates the final stripped artifact.
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    $out/bin/codexbar --version | grep -F "CodexBar ${version}"
    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "CLI reporting AI coding provider usage limits, powering CodexBar desktop integrations";
    homepage = "https://github.com/steipete/CodexBar";
    changelog = "https://github.com/steipete/CodexBar/blob/main/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "codexbar";
    platforms = lib.platforms.linux;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
