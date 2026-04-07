#!/usr/bin/env -S just --justfile

_:
    @just --list

alias fmt := format

[group('ci')]
format:
    prek run --hook-stage pre-commit --all-files

[group('ci')]
lint:
    actionlint

[group('ci')]
dispatch-flake-update:
    gh workflow run flake-update.yaml --ref main

[group('ci')]
dispatch-devenv-update:
    gh workflow run devenv-update.yaml --ref main

show:
    nix flake show
