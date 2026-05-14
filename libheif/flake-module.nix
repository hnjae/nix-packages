let
  packageName = "libheif";
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.${packageName} = pkgs.${packageName}.overrideAttrs (old: {
        buildInputs =
          (old.buildInputs or [ ])
          ++ (with pkgs; [
            openh264
            openjpeg
            vvenc
            x264
          ]);

        cmakeFlags = (old.cmakeFlags or [ ]) ++ [
          "-DWITH_VVENC=ON"
          "-DWITH_X264=ON"
          "-DWITH_OpenH264_DECODER=ON"
          "-DWITH_JPEG_DECODER=ON"
          "-DWITH_JPEG_ENCODER=ON"
          "-DWITH_OpenJPEG_DECODER=ON"
          "-DWITH_OpenJPEG_ENCODER=ON"
        ];
      });
    };
}
