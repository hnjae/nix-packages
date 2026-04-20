let
  packageName = "duf";
in
{
  perSystem =
    {
      pkgs,
      lib,
      ...
    }:
    {
      packages.${packageName} = pkgs.buildEnv {
        name = pkgs.duf.name;
        meta = pkgs.duf.meta;
        paths = [
          pkgs.duf # for man page
          (lib.hiPrio (
            pkgs.writeScriptBin "duf" # sh
              ''
                #!${pkgs.dash}/bin/dash

                set -eu

                exec '${lib.getExe pkgs.duf}' \
                '-usage-threshold=0.7,0.8' \
                '-hide-mp=/nix/store,/var/lib/*,/etc/*' \
                '-hide-fs=efivarfs,devtmpfs' \
                '-theme=ansi' \
                "$@"
              ''
          ))
        ];
      };
    };
}
