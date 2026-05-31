#!/usr/bin/env -S just --justfile

set fallback
set unstable

root := justfile_directory()

_:
    @just --list

alias fmt := format

[group('ci')]
format:
    prek run --hook-stage pre-commit --all-files

[group('ci')]
lint-fix:
    deadnix --edit

alias lint := static-checks

[group('ci')]
static-checks:
    statix check
    deadnix --fail

    typos
    rumdl check
    editorconfig-checker

[group('ci')]
flake-check:
    nix --no-warn-dirty flake check

[group('ci')]
check: static-checks flake-check

[group('ci')]
dispatch-flake-update:
    gh workflow run flake-update.yaml --ref main

[group('ci')]
dispatch-devenv-update:
    gh workflow run devenv-update.yaml --ref main

[group('nix')]
flake-show:
    nix --no-warn-dirty flake show

[group('nix')]
build package="":
    #!/usr/bin/env bash
    set -euo pipefail

    package="{{ package }}"
    root="{{ root }}"
    invocation_dir="{{ invocation_directory() }}"

    if [ -z "$package" ]; then
        if [ "$invocation_dir" = "$root" ]; then
            echo "ERR: pass a package name, or run from a package directory" >&2
            exit 1
        fi

        relative_dir="${invocation_dir#"$root"/}"
        package="${relative_dir%%/*}"
    fi

    NIXPKGS_ALLOW_UNFREE=1 nix build --impure "$root#$package"

[group('nix')]
choose-build:
    #!/usr/bin/env bash
    set -euo pipefail

    system="$(nix eval --impure --raw --expr builtins.currentSystem)"
    package="$(
        nix eval --impure --json "{{ root }}#packages.$system" --apply builtins.attrNames \
            | jq -r '.[]' \
            | fzf
    )"

    NIXPKGS_ALLOW_UNFREE=1 nix build --impure "{{ root }}#$package"
