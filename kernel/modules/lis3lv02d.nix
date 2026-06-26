{ lib, seeed-linux-dtoverlays, config, ... }:
let
  callPackage =
    (lib.flip config.boot.kernelPackages.callPackage)
      { src = seeed-linux-dtoverlays; };
in
lib.mkIf
  config.reTerminal.modules.expansionPack.enable-accelerometer-support
  {
    boot.kernelModules = [ "lis3lv02d" ];

    boot.extraModulePackages =
      [(
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
              pname = "${kernel.name}_module-lis3lv02d";
              version = "0.1";

              inherit src;

              sourceRoot = "modules/lis3lv02d";
              hardeningDisable = [ "pic" "format" ];
              nativeBuildInputs = kernel.moduleBuildDependencies;

              makeFlags =
                kernelModuleMakeFlags
              ++
                [
                  "KVERSION=${kernel.modDirVersion}"
                  "INSTALL_MOD_PATH=$(out)"
                ];

              meta =
                {
                  description = "A linux kernel IIO-driver that provides access to data from a 3-axis accelerometer via `/sys/bus/iio/devices/iio:device<N>/*`.";

                  homepage = "https://github.com/Seeed-Studio/seeed-linux-dtoverlays/blob/fe6b8c8dfddd3c63f39f895e8a49f4612340a3fe/modules/lis3lv02d/README.md";
                  platforms = lib.platforms.linux;

                  # The base repo is licensed as GPL2, inherited from the Linux Kernel.
                  #
                  # `Makefile` is licensed MIT by Zhangqun Ming at Seeed Studio.
                  # I would think that the `dkms.conf` was also intended be licensed MIT,
                  # but because it lacks an explicit license notice, we must assume the
                  # repo-wide license is applied (GPL2).
                  #
                  # The C source files (including headers) are licensed GPL2 by a number
                  # of authors, which seem to originate from
                  # STMicroelectronics.
                  license = [ lib.licenses.gpl2 lib.licenses.mit ];
                };
            }
        )
      )];
  }
