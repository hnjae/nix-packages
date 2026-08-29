# Repository Guidelines

## Project Structure & Module Organization

- Root [`flake.nix`](./flake.nix) defines supported systems and exports available packages with `callPackage`.
- Keep each package in its own directory, named after the exported package.
- Package layout: `package/package.nix`
- Shared dev setup lives in [`devenv.nix`](./devenv.nix). CI lives in [`.github/workflows/ci.yaml`](./.github/workflows/ci.yaml).

## Build, Test, and Development Commands

- `nix flake show` shows exported flake outputs.
- `prek run --hook-stage pre-commit --all-files` runs the formatter and pre-commit suite.
- `nix flake check --impure --no-write-lock-file` is the required validation and matches CI.

## Coding Style & Naming Conventions

- Follow [`.editorconfig`](.editorconfig): use spaces, 2-space `*.nix`, 4-space `justfile`, Markdown, and shell.
- Prefer small, composable Nix expressions over large inline attribute sets.

## GUI Application Packaging

- Target Wayland only: apps run as native Wayland through Ozone (`--ozone-platform-hint=auto` and the Wayland IME/text-input flags in the wrapper). X11 operation is not a goal; do not add X11-only workarounds or verify against X11.
- Present one coherent identity per GUI app: binary name, desktop entry, icon name, `meta.mainProgram`, and the window class the app actually reports must all agree.
- Derive the app id from upstream when one exists (Tauri `identifier`, electron-builder `appId`, the official `.desktop` name, Chromium `--class` conventions). When upstream declares none, keep the app's own identity instead of inventing one.
- `StartupWMClass` must equal the window's real WM_CLASS res_class, or docks and launchers will not group or launch correctly. Point `Exec` at the canonical binary.
- Renames must not relocate user data directories (`~/.config/<app>`): leave compile-time identifiers that drive data paths (e.g. a Tauri `identifier`) untouched.
- Window classes are toolkit-specific: Chromium honors `--class`; Electron ignores it and derives the class from its own package.json (`desktopName` basename, else `productName`/`name`). Patching app internals to force a class (see `obsidian`) is a last resort.
- Verify empirically on a real Wayland session: run the packaged app and confirm it starts and docks/launchers group it under the declared app id. Give Chromium apps a temporary `--user-data-dir` so a running instance does not absorb the launch. `nix flake check` does not cover any of this.
- Use `--replace-warn` (not `--replace-fail`) when rewriting upstream desktop entries, so upstream formatting drift degrades into a warning instead of breaking updates.

## Testing Guidelines

- There is no separate unit-test suite; run `nix flake check` for required validation.

## Commit & Pull Request Guidelines

- This repository follows a trunk-based workflow with short-lived branches.
- Direct pushes to `main` are not possible; changes must land through a PR.
- PRs should summarize the change.
