# Repository Guidelines

## Project Structure & Module Organization

- Root [`flake.nix`](./flake.nix) defines supported systems and imports package modules.
- Keep each package in its own directory, named after the exported package.
- Package layout: `package/flake-module.nix`, `package/derivation.nix`
- Shared dev setup lives in [`devenv.nix`](./devenv.nix). CI lives in [`.github/workflows/ci.yml`](./.github/workflows/ci.yml).

## Build, Test, and Development Commands

- `nix flake show` shows exported flake outputs.
- `prek run --hook-stage pre-commit --all-files` runs the formatter and pre-commit suite.
- `nix flake check --impure --no-write-lock-file` is the required validation and matches CI.

## Coding Style & Naming Conventions

- Follow [`.editorconfig`](.editorconfig): use spaces, 2-space `*.nix`, 4-space `justfile`, Markdown, and shell.
- Prefer small, composable Nix expressions over large inline attribute sets.

## Testing Guidelines

- There is no separate unit-test suite; run `nix flake check` for required validation.

## Commit & Pull Request Guidelines

- This repository follows a trunk-based workflow with short-lived branches.
- Direct pushes to `main` are not possible; changes must land through a PR.
- Use Conventional Commits specification.
- PRs should summarize the change.
