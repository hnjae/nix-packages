{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  nix-update-script,
  nodejs,
  ...
}:
let
  appId = "md.obsidian.Obsidian";
  version = "1.13.7";
  appImage = fetchurl {
    url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage";
    hash = "sha256-4NjgphFiTejJx9zYqeZIJ5+woNVS+qExK35POl+nJmM=";
  };
in
appimageTools.wrapAppImage rec {
  pname = "obsidian";
  inherit version;

  src = appimageTools.extract {
    inherit pname version;
    src = appImage;
    postExtract = ''
      ${nodejs}/bin/node <<'EOF'
      const crypto = require("crypto");
      const fs = require("fs");

      const asarPath = process.env.out + "/resources/app.asar";
      const appId = "${appId}";
      const archive = fs.readFileSync(asarPath);
      const headerSize = archive.readUInt32LE(4);
      const jsonSize = archive.readUInt32LE(12);
      const headerStart = 16;
      const header = JSON.parse(archive.subarray(headerStart, headerStart + jsonSize).toString());
      const packageFile = header.files["package.json"];
      const dataStart = 8 + headerSize;
      const packageStart = dataStart + Number(packageFile.offset);
      const packageEnd = packageStart + packageFile.size;

      if (packageEnd !== archive.length) {
        throw new Error("Cannot patch app.asar: package.json is not the last file");
      }

      const packageJson = JSON.parse(archive.subarray(packageStart, packageEnd).toString());
      packageJson.desktopName = appId + ".desktop";

      const packageData = Buffer.from(JSON.stringify(packageJson, null, "\t") + "\n");
      const packageHash = crypto.createHash("sha256").update(packageData).digest("hex");
      packageFile.size = packageData.length;
      packageFile.integrity = {
        algorithm: "SHA256",
        hash: packageHash,
        blockSize: 4194304,
        blocks: [packageHash],
      };

      const headerData = Buffer.from(JSON.stringify(header));
      if (headerData.length > jsonSize) {
        throw new Error("Cannot patch app.asar: updated header is larger than the original header");
      }

      fs.writeFileSync(
        asarPath,
        Buffer.concat([
          archive.subarray(0, headerStart),
          headerData,
          Buffer.alloc(jsonSize - headerData.length, 0x20),
          archive.subarray(headerStart + jsonSize, packageStart),
          packageData,
        ])
      );
      EOF
    '';
  };

  nativeBuildInputs = [ makeWrapper ];
  extraInstallCommands = ''
    mv "$out/bin/${pname}" "$out/bin/${appId}"

    wrapProgram $out/bin/${appId} \
      --set LC_ALL en_IE.UTF-8 \
      --add-flags "--no-sandbox" \
      --add-flags "--enable-features=WaylandWindowDecorations" \
      --add-flags "--enable-features=UseOzonePlatform" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--enable-wayland-ime" \
      --add-flags "--wayland-text-input-version=3"


    shopt -s nullglob

    desktopFile=
    for candidate in ${src}/*.desktop ${src}/usr/share/applications/*.desktop; do
      if grep -Iq '^\[Desktop Entry\]' "$candidate"; then
        desktopFile="$candidate"
        break
      fi
    done

    if [ -z "$desktopFile" ]; then
      echo "ERR: No desktop entry found in extracted AppImage" >&2
      exit 1
    fi

    install -m 444 -D "$desktopFile" "$out/share/applications/${appId}.desktop"

    substituteInPlace "$out/share/applications/${appId}.desktop" \
      --replace-warn 'Exec=AppRun --no-sandbox %U' 'Exec=${appId} %U' \
      --replace-warn 'Icon=obsidian' 'Icon=${appId}' \
      --replace-warn 'StartupWMClass=obsidian' 'StartupWMClass=${appId}'

    ${lib.concatMapStrings
      (size: ''
        mkdir -p "$out/share/icons/hicolor/${size}x${size}/apps"
        cp --reflink=auto "${src}/usr/share/icons/hicolor/${size}x${size}/apps/obsidian.png" \
          "$out/share/icons/hicolor/${size}x${size}/apps/${appId}.png"
      '')
      [
        "16"
        "24"
        "32"
        "48"
        "64"
        "128"
        "256"
        "512"
      ]
    }
  '';

  passthru = {
    src = appImage;
    updateScript = nix-update-script {
      extraArgs = [ "--flake" ];
    };
  };

  meta = {
    description = "A powerful knowledge base that works on top of a local folder of plain text Markdown files";
    homepage = "https://obsidian.md";
    license = lib.licenses.obsidian;
    mainProgram = appId;
    platforms = [ "x86_64-linux" ];
  };
}
