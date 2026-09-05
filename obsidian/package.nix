{
  obsidian,
  fetchurl,
  gh,
  jq,
  lib,
  makeDesktopItem,
  nix-update,
  writeShellApplication,
  ...
}:
let
  appId = "md.obsidian.Obsidian";

  # Pinned on top of the nixpkgs derivation until nixpkgs stable catches up.
  version = "1.13.7";
  usePin = lib.versionOlder obsidian.version version;

  src = fetchurl {
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian-${version}.tar.gz";
    hash = "sha256-08vjdcv6QCTbGRC5gZFkn0E0xcSK7l5gtudxOYfc2yg=";
  };

  # GitHub "latest" on obsidianmd/obsidian-releases can be a mobile-only
  # release (apk assets only, desktop assets absent), so the desktop channel
  # must be resolved by asset presence, matching obsidian.md's download page.
  updateScript = writeShellApplication {
    name = "obsidian-update-script";
    runtimeInputs = [
      gh
      jq
      nix-update
    ];
    text = ''
      attr="''${1:-$UPDATE_NIX_ATTR_PATH}"

      # shellcheck disable=SC2016
      desktop_version="$(
        gh api --paginate --slurp repos/obsidianmd/obsidian-releases/releases | jq -r '
          [.[][]
            | select(.draft == false)
            | select(
              . as $release
              | $release.assets
              | any(.name == "obsidian-" + ($release.tag_name | ltrimstr("v")) + ".tar.gz")
            )]
          | first | .tag_name | ltrimstr("v")
        '
      )"

      exec nix-update --flake --version "$desktop_version" "$attr"
    '';
  };

  desktopItem = makeDesktopItem {
    name = appId;
    desktopName = "Obsidian";
    comment = "Knowledge base";
    exec = "${appId} %U";
    icon = appId;
    startupWMClass = appId;
    categories = [ "Office" ];
    mimeTypes = [ "x-scheme-handler/obsidian" ];
  };
in
(obsidian.override {
  commandLineArgs = "--enable-features=WaylandWindowDecorations --ozone-platform-hint=auto --enable-wayland-ime --wayland-text-input-version=3";
}).overrideAttrs
  (
    old:
    {
      passthru = (old.passthru or { }) // {
        updateScript = if usePin then updateScript else null;
      };

      postInstall = (old.postInstall or "") + ''
        mv $out/bin/obsidian $out/bin/${appId}

        wrapProgram $out/bin/${appId} \
          --set LC_ALL en_IE.UTF-8

        rm -f $out/share/applications/obsidian.desktop
        install -m 444 -D "${desktopItem}/share/applications/${appId}.desktop" \
          "$out/share/applications/${appId}.desktop"

        for icon in $out/share/icons/hicolor/*x*/apps/obsidian.png; do
          mv "$icon" "$(dirname "$icon")/${appId}.png"
        done
      '';

      meta = (old.meta or { }) // {
        mainProgram = appId;
        platforms = [ "x86_64-linux" ];
      };
    }
    // lib.optionalAttrs usePin {
      inherit version src;
    }
  )
