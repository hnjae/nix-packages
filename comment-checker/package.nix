{
  buildGoModule,
  fetchFromGitHub,
  lib,
  supportedSystems,
  ...
}:
buildGoModule rec {
  pname = "comment-checker";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "code-yeongyu";
    repo = "go-claude-code-comment-checker";
    rev = "v${version}";
    hash = "sha256-RyZlVPJ+G3Vvt5Mhja7mxSe8bd+BfsYqbbrfqjjCbYE=";
  };

  subPackages = [ "cmd/comment-checker" ];

  proxyVendor = true;

  env.CGO_ENABLED = 1;

  ldflags = [
    "-s"
    "-w"
  ];

  vendorHash = "sha256-cW/cWo6k7aA/Z2w6+CBAdNKhEiWN1cZiv/hl2Mto6Gw=";

  meta = {
    description = "Claude Code and OpenCode hook that blocks unnecessary code comments";
    homepage = "https://github.com/code-yeongyu/go-claude-code-comment-checker";
    license = lib.licenses.mit;
    mainProgram = "comment-checker";
    platforms = supportedSystems;
  };
}
