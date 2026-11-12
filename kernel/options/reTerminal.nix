{
  lib,
  pkgs,

  seeed-linux-dtoverlays,
  # packages-kernelModules,

  config,

  ...
}:
let
  inherit (lib) types;

  inherit (lib.mkOption {}) _type;

  deviceTree = config.hardware.deviceTree;
  reTerminal = config.reTerminal;
in
{

  options.reTerminal =
    {
      enable = lib.mkEnableOption "reTerminal support";

      # TODO: Move each of these into their respective nix file.
      modules =
        {
          expansionPack =
            {
              inherit _type;

              description =
                ''
                  Settings regarding device-tree overlays and kernel modules
                  that add support for various components and/or features of
                  [Seeed Studio's reTerminal Expansion Board](https://www.seeedstudio.com/reTerminal-E10-1-p-5376.html).
                '';

              type =
                types.submodule
                  {
                    # ../modules/bq24179_charger.nix
                    options.enable-battery-support =
                      {
                        inherit _type;

                        type = types.boolByOr;
                        default = false;
                        example = true;

                        description =
                          # TODO: Elaborate.
                          ''
                            Add drivers for interfacing with the bq24179 charging IC.
                          '';
                      };

                    # ../modules/lis3lv02d.nix
                    options.enable-proximity-sensor-support =
                      {
                        inherit _type;

                        type = types.boolByOr;
                        default = false;
                        example = true;

                        description =
                          # TODO: Elaborate.
                          ''
                            Add drivers for interfacing with the lis3lv02d proximity-sensor.
                          '';
                      };

                    # ../modules/ltr30x.nix
                    options.enable-accelerometer-support =
                      {
                        inherit _type;

                        type = types.boolByOr;
                        default = false;
                        example = true;

                        description =
                          # TODO: Elaborate.
                          ''
                            Add drivers for interfacing with the ltr30x accelerometer IC.
                          '';
                      };
                  };
            };
        };
    };

  config =
    lib.mkIf
      reTerminal.enable
      {
        hardware =
          {
            # # overridden by ../modules/mipi_dsi.nix if battery support is enabled.
            # #
            # # /boot/firmware/config.txt
            # # dtoverlay=reTerminal
            # raspberry-pi.config.all.dt-overlays.reTerminal-overlay =
            #   # lib.mkIf
            #   #   (!reTerminal.modules.enable-battery-support)
            #   {
            #     enable = true;
            #     params = {};
            #   }
            #   ;

            deviceTree.overlays =
              [
                {
                  name = "reTerminal-overlay";
                  dtsFile = seeed-linux-dtoverlays + "/overlays/rpi/reTerminal-overlay.dts";
                  filter = "*bcm2711*.dtb";
                }
              ]
              ;

            # deviceTree.overlays = [ (seeedOverlayNamed "reTerminal") ];
          };
      };
}
