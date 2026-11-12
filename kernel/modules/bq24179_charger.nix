{ lib, seeed-linux-dtoverlays, config, ... }:
let
  callPackage =
    (lib.flip config.boot.kernelPackages.callPackage)
      { src = seeed-linux-dtoverlays; };
in
lib.mkIf
  config.reTerminal.modules.expansionPack.enable-battery-support
  {
    boot.kernelModules = [ "bq24179_charger" ];

    boot.extraModulePackages =
      [
        (
          callPackage
          (
            {
              kernel,
              kernelModuleMakeFlags,

              stdenv,

              src,
            }:
            stdenv.mkDerivation
              {
                pname = "${kernel.name}_module-bq24179_charger";
                version = "0.1";

                inherit src;

                sourceRoot = "modules/bq24179_charger";
                hardeningDisable = [ "pic" "format" ];
                nativeBuildInputs = kernel.moduleBuildDependencies;

                makeFlags =
                  kernelModuleMakeFlags
                ++
                  [
                    "KVERSION=${kernel.modDirVersion}"
                    "INSTALL_MOD_PATH=$(out)"
                  ]
                  ;

                meta =
                  {
                    description = "A linux kernel driver that provides access to data from a buck-boost charging IC.";
                    homepage = "https://github.com/Seeed-Studio/seeed-linux-dtoverlays/blob/fe6b8c8dfddd3c63f39f895e8a49f4612340a3fe/modules/bq24179_charger";
                    platforms = lib.platforms.linux;

                    # The base repo is licensed as GPL2, inherited from the Linux Kernel.
                    #
                    # `Makefile` is licensed MIT by Zhangqun Ming at Seeed Studio.
                    # I would think that the `dkms.conf` was also intended be licensed MIT,
                    # but because it lacks an explicit license notice, we must assume the
                    # repo-wide license is applied (GPL2).
                    #
                    # `bq24179_charger.h` and `bq24179_charger.c` are licensed GPL2 by
                    # Texas Instruments.
                    license = [ lib.licenses.gpl2 lib.licenses.mit ];
                  };
              }
          )
        )
      ]
      ;
  }
