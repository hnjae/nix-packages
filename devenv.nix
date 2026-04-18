{
  pkgs,
  lib,
  ...
}:
{
  packages = with pkgs; [
    # static checkers (linters, ...)
    actionlint
    editorconfig-checker

    # dev tools
    dpkg
  ];

  languages.nix.enable = true;

  git-hooks.hooks = {
    detect-private-keys.enable = true;
    actionlint.enable = true;
    typos.enable = true;

    # Formatters
    nixfmt.enable = true;
    rumdl.enable = true;
    biome.enable = true;
    taplo.enable = true;
    yamlfmt.enable = true;
    just-fmt = {
      enable = true;
      name = "just-fmt";
      package = pkgs.just;
      files = ''(^|/)(\.)?justfile$'';
      entry = toString (
        pkgs.writeShellScript "precommit-just-fmt" ''
          set -euo pipefail

          for file in "$@"; do
            ${lib.getExe pkgs.just} --unstable --fmt --justfile "$file"
          done
        ''
      );
    };
    shell-fmt = {
      enable = true;
      package = pkgs.symlinkJoin {
        name = "shell-fmt";
        paths = with pkgs; [
          shellharden
          shellcheck
          shfmt
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
      entry = toString (
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
