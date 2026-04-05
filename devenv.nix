{
  pkgs,
  ...
}:
{
  packages = [
    pkgs.git
    pkgs.just
    pkgs.actionlint
  ];

  languages.nix.enable = true;

  git-hooks.hooks = {
    detect-private-keys.enable = true;
    nixfmt.enable = true;
    rumdl.enable = true;
    taplo.enable = true;
    yamlfmt.enable = true;
    just-fmt = {
      enable = true;
      name = "just-fmt";
      package = pkgs.just;
      files = ''(^|/)(\.)?justfile$'';
      entry = builtins.toString (
        pkgs.writeShellScript "precommit-just-fmt" ''
          set -euo pipefail

          for file in "$@"; do
            ${pkgs.just}/bin/just --unstable --fmt --justfile "$file"
          done
        ''
      );
    };
    shell-fmt = {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "shell-fmt";
        paths = [
          pkgs.shellharden
          pkgs.shellcheck
          pkgs.shfmt
        ];
      };
      files = ''
        (?x)^(
          .*\.(sh|bash)$|
          \.envrc(\..+)?$|
          \.env(\..+)?$|
          \.profile$
        )
      '';
      entry = builtins.toString (
        pkgs.writeShellScript "shell-fmt" ''
          set -euo pipefail

          for file in "$@"; do
            shellharden --replace "$file"
            shellcheck "$file"
            shfmt --indent 4 --simplify --write "$file"
          done
        ''
      );
    };
  };
}
