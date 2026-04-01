#!/usr/bin/env -S just --justfile

_:
    @just --list

alias fmt := format

[group('ci')]
format:
    prek run --hook-stage pre-commit --all-files
