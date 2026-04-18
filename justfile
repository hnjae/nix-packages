#!/usr/bin/env -S just --justfile

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
