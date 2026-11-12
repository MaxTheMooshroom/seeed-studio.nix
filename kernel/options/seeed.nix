{
  lib,

  seeed-linux-dtoverlays,

  config,
  ...
}:
let
  inherit (lib) types;

  deviceTree = config.hardware.deviceTree;
  seeed = config.seeed;

  inherit (lib.mkOption {}) _type;

  find-dt-files =
    let
      turn = f: g: x: f (g x);
      notNull = x: !isNull x;

      match-dt = builtins.match "^(.*)\\.dt[sb]$";
      into-stem-fn = turn builtins.head match-dt;
      is-dt-match = turn notNull match-dt;
      attrs-filter =
        name: value:
        value == "regular"
      &&
        (is-dt-match name)
        ;
      filterDir = turn (lib.filterAttrs attrs-filter) builtins.readDir;
      dt-files = turn builtins.attrNames filterDir;
      into-stem = turn (map into-stem-fn) dt-files;
    in
      into-stem
    ;

  dtb-bases = find-dt-files (deviceTree.dtbSource + "/broadcom");
  dt-overlays = find-dt-files (seeed-linux-dtoverlays + "/overlays/rpi");

  dtb-base = types.enum dtb-bases;

  seeedOverlay =
    types.submodule
      {
        options =
          {
            base-name =
              {
                inherit _type;

                type = dtb-base;
                description = "The name of the overlay's base device-tree (without the extension)";
                example = "bcm2711-rpi-cm4";
              }
              ;

            name =
              {
                inherit _type;

                type = types.str;
                description = "The overlay's name";
                example = lib.literalExpression "reTerminal";
              }
              ;

            kind =
              {
                inherit _type;

                type = types.enum [ "dts" "dtbo" ];
                description = "Whether the overlay is in source form or already compiled";
                default = "dtbo";
                example = lib.literalExpression "dts";
              }
              ;

            path =
              {
                inherit _type;

                type = types.pathInStore;
                description = "Where the overlay can be found";
                example = lib.literalExpression "./my-overlay.dtbo";
              }
              ;
          }
          ;
      }
    ;

  resolveSeeedOverlay =
    { base-name, name, kind, path }:
    {
      inherit name;
      filter = "${base-name}.dtb";
      #
    }
    ;
in
  {
    options.seeed =
      {
        enable = lib.mkEnableOption "Seeed Studio hardware-support";
        overlays =
          {
            inherit _type;

            type = types.listOf seeedOverlay;
            description = ''
              A list of references to overlays found from
              [github:Seeed-Studio/seeed-linux-dtoverlays](github:Seeed-Studio/seeed-linux-dtoverlays/0452c94b085a7b2191d493087394d4e3267d9193)
              to add to `hardware.deviceTree.overlays`
            '';
            apply = map resolveSeeedOverlay;
          }
          ;
      }
      ;

    config.hardware.deviceTrees.overlays =
      lib.mkIf
        seeed.enabled
        seeed.overlays
      ;
  }
