{ pkgs, nixos-raspberrypi, seeed-linux-dtoverlays, ... }:
let
  inherit (nixos-raspberrypi.legacyPackages.aarch64-linux)
    linuxPackagesFor
    linux_rpi4_v6_18_33
    ;
in
{
  imports =
    [
      ./options
      ./modules
    ]
    ;

  boot.kernelPackages = linuxPackagesFor linux_rpi4_v6_18_33;

  _module.args.seeed-linux-dtoverlays-patched =
    pkgs.runCommand
      "seeed-linux-dtoverlays-patched"
      {}
      ''
        cp -r "${seeed-linux-dtoverlays}" $out
        chmod -R +w $out

        substituteInPlace $out/modules/**/Makefile \
          --replace-warn '/lib/modules/$(KVERSION)/build' '$(KERNEL_DIR)'
      ''
    ;
}
