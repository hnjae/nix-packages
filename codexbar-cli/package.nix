{
  buildFHSEnv,
  curl,
  fetchurl,
  lib,
  lsof,
  nix-update-script,
  openssh,
  procps,
  stdenv,
  tzdata,
  which,
}:
let
  version = "0.64.1";

  codexbar-cli-unwrapped = stdenv.mkDerivation {
    pname = "codexbar-cli-unwrapped";
    inherit version;

    src = fetchurl {
      url = "https://github.com/steipete/CodexBar/releases/download/v${version}/CodexBarCLI-v${version}-linux-musl-${stdenv.hostPlatform.uname.processor}.tar.gz";
      hash =
        if stdenv.hostPlatform.isAarch64 then
          "sha256-oygcik7RgPY9axV77TMNKOS6bMn1riLHLK9PLAkRGwI="
        else
          "sha256-S86hfbvU/aOyhI137Q2/oV30UrixhHL9/hUHpX/BQUw=";
    };

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

    meta = {
      description = "CLI reporting AI coding provider usage limits, powering CodexBar desktop integrations";
      homepage = "https://github.com/steipete/CodexBar";
      changelog = "https://github.com/steipete/CodexBar/blob/main/CHANGELOG.md";
      license = lib.licenses.mit;
      platforms = lib.platforms.linux;
      sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    };
  };

  # The binary resolves provider CLIs and helpers through hardcoded FHS paths
  # (/usr/bin/which, /usr/bin/env, /usr/bin/curl, /bin/ps, ...). On non-FHS
  # hosts like NixOS those files are absent, and a failed launch makes Swift
  # Foundation trap with SIGILL before the CLI's own error handling runs (same
  # family as upstream steipete/CodexBar#2127). Export the CLI through a
  # bubblewrap FHS env that provides those paths; /nix, /run, /home and other
  # host trees are bind-mounted by buildFHSEnv, so user config and login-shell
  # PATH detection keep working. tzdata backs /usr/share/zoneinfo inside the
  # env for hosts whose /etc/localtime points there.
  codexbar-cli = buildFHSEnv {
    pname = "codexbar-cli";
    inherit version;
    executableName = "codexbar";

    targetPkgs = pkgs: [
      codexbar-cli-unwrapped
      curl
      lsof
      openssh
      procps
      tzdata
      which
    ];
    runScript = "codexbar";

    passthru = {
      unwrapped = codexbar-cli-unwrapped;
      updateScript = nix-update-script {
        attrPath = "codexbar-cli.unwrapped";
        extraArgs = [ "--flake" ];
      };
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
  };
in
# buildFHSEnv forces Linux-only tooling (glibc, bubblewrap) into evaluation;
# keep the non-Linux branch lazy so the flake's availableOn filter can drop
# the package on those systems without evaluating the env.
if stdenv.hostPlatform.isLinux then codexbar-cli else codexbar-cli-unwrapped
