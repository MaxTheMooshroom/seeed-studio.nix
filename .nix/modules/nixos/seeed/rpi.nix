{ lib, seeed-linux-dtoverlays, config, ... }:
let
  inherit (lib) types;

  inherit (lib.mkOption {}) _type;

  path = seeed-linux-dtoverlays + "/overlays/rpi";

  splitLines = lib.splitString "\n";

  kernel-modules =
    splitLines
      (builtins.readFile (path + "/config.txt"))
    ;
in
  {
    options.seeed.rpi =
      {
        enable = lib.mkEnableOption "Seeed Studio's rpi overlays";
      }
      ;
  }
