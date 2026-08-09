{
  fetchFromGitHub,
  fetchurl,
  lib,
  nix-update-script,
  rustPlatform,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "comment-checker";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "go-claude-code-comment-checker";
    rev = "v${version}";
    hash = "sha256-rV51+vo+6BEU3vh4/WVZxRbNXmvqyrAjMwl872+4MW0=";
  };

  cargoHash = "sha256-OieMIlyo4ENmakJIiqHVwSF7wk96TN15FnjbrVYTyaA=";

  env = {
    TSLP_LINK_MODE = "static";
    TSLP_SOURCE_BUNDLE_URL = "file://${
      fetchurl {
        url = "https://github.com/kreuzberg-dev/tree-sitter-language-pack/releases/download/v1.8.1/parser-sources-1.8.1.tar.zst";
        hash = "sha256-Kcds8n8X7dE5gRhVPd3pvouemXDAAXs4fFNGbPLkhxc=";
      }
    }";
  };

  cargoBuildFlags = [
    "-p"
    pname
  ];

  cargoTestFlags = cargoBuildFlags;

  passthru.updateScript = nix-update-script {
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "Claude Code and OpenCode hook that blocks unnecessary code comments";
    homepage = "https://github.com/code-yeongyu/go-claude-code-comment-checker";
    license = lib.licenses.mit;
    mainProgram = "comment-checker";
    platforms = lib.platforms.unix;
  };
}
