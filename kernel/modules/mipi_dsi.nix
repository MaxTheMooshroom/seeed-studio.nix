{ lib, seeed-linux-dtoverlays-patched, config, ... }:
let
  callPackage =
    (lib.flip config.boot.kernelPackages.callPackage)
      { src = seeed-linux-dtoverlays-patched; };
in
{
  options.reTerminal.modules.enable-touch-display =
    lib.mkOption
      {
        type = lib.types.boolByOr;
        default = true;
        example = false;
        description =
          # TODO: Elaborate.
          ''
            Whether the display should be enabled (including the touch interface).
          '';
      };

  config =
    lib.mkIf
      (config.reTerminal.enable && config.reTerminal.modules.enable-touch-display)
      {
        hardware =
          {
            # /boot/firmware/config.txt
            # dtoverlay=reTerminal,tp_rotate=1
            raspberry-pi.config.all.dt-overlays.reTerminal =
              {
                enable = true;
                params.tp_rotate = true;
              };
          };

        boot =
          {
            kernelModules = [ "mipi_dsi" ];

            extraModulePackages =
              [(
                callPackage
                (
                  {
                    kernel,
                    kernelModuleMakeFlags,

                    lib,
                    stdenv,

                    src,
                  }:

                  stdenv.mkDerivation
                    {
                      pname = "${kernel.name}_module-mipi_dsi";
                      version = "0.1";

                      # inherit src;
                      src = "${src}/modules/mipi_dsi";

                      # sourceRoot = "source/modules/mipi_dsi";
                      hardeningDisable = [ "pic" "format" ];
                      nativeBuildInputs = kernel.moduleBuildDependencies;

                      makeFlags =
                        kernelModuleMakeFlags
                      ++
                        [
                          "KVERSION=${kernel.modDirVersion}"
                          "KERNEL_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
                          "INSTALL_MOD_PATH=$(out)"
                        ];

                      meta =
                        {
                          description = "A linux kernel driver for a MIPI-DSI panel and touch panel attached to the Raspberry Pi CM4's I2C bus.";
                          homepage = "https://github.com/Seeed-Studio/seeed-linux-dtoverlays/blob/fe6b8c8dfddd3c63f39f895e8a49f4612340a3fe/modules/mipi_dsi/README.md";
                          platforms = lib.platforms.linux;

                          # The base repo is licensed as GPL2, inherited from the Linux Kernel.
                          #
                          # `Makefile` is licensed MIT by Zhangqun Ming at Seeed Studio.
                          # I would think that the `dkms.conf` was also intended be licensed MIT,
                          # but because it lacks an explicit license notice, we must assume the
                          # repo-wide license is applied (GPL2).
                          #
                          # All other files for this module are each explicitly licensed GPL2
                          # by Zhangqun Ming at Seeed Studio, except for `touch_panel.c`.
                          # As such, we must assume the inherited repo-wide license applies,
                          # which is also GPL2.
                          license = [ lib.licenses.gpl2 lib.licenses.mit ];
                        };
                    }
                )
              )];
          };
      };
}
