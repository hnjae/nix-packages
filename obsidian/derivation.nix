{
  appimageTools,
  fetchurl,
  lib,
  makeWrapper,
  nodejs,
  supportedSystems,
  ...
}:
let
  appId = "md.obsidian.Obsidian";
in
appimageTools.wrapAppImage rec {
  pname = "obsidian";
  version = "1.12.7";

  src = appimageTools.extract {
    inherit pname version;
    src = fetchurl {
      url = "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/Obsidian-${version}.AppImage";
      hash = "sha256-9ti5b+aFqGMsgZzAk6JIrOD2urQQ9EpskpomEbHrsXw=";
    };
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


    install -m 444 -D ${src}/obsidian.desktop $out/share/applications/${appId}.desktop

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
        "32"
        "48"
        "64"
        "128"
        "256"
        "512"
      ]
    }
  '';

  meta = {
    description = "A powerful knowledge base that works on top of a local folder of plain text Markdown files";
    homepage = "https://obsidian.md";
    license = lib.licenses.obsidian;
    mainProgram = appId;
    platforms = supportedSystems;
  };
}
