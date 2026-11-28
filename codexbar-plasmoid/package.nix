# SPDX-License-Identifier: GPL-3.0-or-later
# SPDX-FileCopyrightText: 2026 KIM Hyunjae

{
  fetchFromGitHub,
  lib,
  nix-update-script,
  stdenv,
}:
let
  version = "0.8.0";
  pluginId = "com.github.psimaker.codexbar";
in
stdenv.mkDerivation {
  pname = "codexbar-plasmoid";
  inherit version;

  src = fetchFromGitHub {
    owner = "psimaker";
    repo = "codexbar-plasmoid";
    tag = "v${version}";
    hash = "sha256-yLf1PxIYxOEDxCdixXRzH6CEuWOSIaRpLRl1YNNgm/A=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    # Plasma discovers plasmoids under XDG data dirs, no build or kpackagetool
    # step needed for a system-wide install.
    mkdir -p $out/share/plasma/plasmoids/${pluginId}
    cp -r metadata.json contents $out/share/plasma/plasmoids/${pluginId}/
    runHook postInstall
  '';

  passthru = {
    inherit pluginId;
    updateScript = nix-update-script {
      extraArgs = [ "--flake" ];
    };
  };

  meta = {
    description = "KDE Plasma 6 panel widget showing AI coding provider usage limits";
    homepage = "https://github.com/psimaker/codexbar-plasmoid";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
