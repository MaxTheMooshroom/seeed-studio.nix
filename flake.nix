{
  description = "NixOS for the Seeed Studio ReTerminal.";

  inputs = {
    # nixpkgs.url = "path:/home/maxine/projects/nixos/nixpkgs";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    # nixpkgs.url = "github:NixOS/nixpkgs/44b5305";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # track an exact commit on the `develop` branch because kernel 6.18
    # is not packaged in a version tag.
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/16d0e78";
    # nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/v1.20260517.0";
    nixos-raspberrypi.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    seeed-linux-dtoverlays =
      {
        # pin to untagged commit on the default branch that
        # "adapt[s] reTerminal drivers and scripts for kernel 6.18 / trixie".
        url = "github:Seeed-Studio/seeed-linux-dtoverlays/0452c94b085a7b2191d493087394d4e3267d9193";
        flake = false;
      }
      ;
  }
  ;

  nixConfig = {
    extra-substituters =
      [
        "https://nixos-raspberrypi.cachix.org"
        "https://nixos-reterminal.cachix.org"
      ]
      ;

    extra-trusted-public-keys =
      [
        "nixos-raspberrypi.cachix.org-1:4iMO9LXa8BqhU+Rpg6LQKiGa2lsNh/j2oiYLNOQ5sPI="
        "nixos-reterminal.cachix.org-1:mFUoyQ8Lz19P4QeQK109A0Ev14UqiDUzq2L5wWmUl00="
      ]
      ;
  }
  ;

  outputs =
    { self, flake-parts, disko, ... }@inputs:
    flake-parts.lib.mkFlake
      { inherit inputs; }
      (
        { lib, ... }:
        {
          systems = lib.systems.flakeExposed;

          imports =
            [
              flake-parts.flakeModules.modules
            ]
            ;

          flake.modules.nixos =
            {
              raspberry-pi-4-b =
                {
                  imports =
                    with inputs.nixos-raspberrypi.nixosModules;
                    [
                      raspberry-pi-4.base
                      raspberry-pi-4.display-vc4
                      raspberry-pi-4.bluetooth
                    ]
                    ;
                }
                ;

              raspberry-pi-cm4-explicit =
                {
                  imports = [ self.modules.nixos.raspberry-pi-4-b ];

                  hardware.deviceTree.name = "bcm2711-rpi-cm4.dtb";
                }
                ;

              /**
                # Synopsis

                `reterminal-support-layer` is NixOS module that adds
                device-tree overlays for the reTerminal, as well as some
                (disabled by default) kernel modules.

                ## Kernel Modules

                The kernel modules can be enabled by adding their name to
                the `boot.kernelModules` option.

                Eg.
                ```nix
                { reTerminal-nix, lib, config, ... }:
                {
                  imports = [ reTerminal-nix.nixosModules.reterminal-support-layer ];
                  boot.kernelModules = [ "bq24179_charger" ];
                }
                ```

                The modules are as follows:

                ### BQ24179 Charging IC Driver (`bq24179_charger`)

                This module provides a driver for communicating with the
                Texas Instruments
                [BQ24179<ins>*</ins>](https://www.ti.com/product/BQ24179),
                a charging IC that is described as a "buck-boost charger for
                1- to 4-cell batteries supporting any USB PD 3.0 profile".
              */
              reterminal-support-layer =
                {
                  imports = [ ./kernel ];

                  reTerminal.enable = true;
                }
                ;

              sd-image =
                {
                  imports =
                    [
                      disko.nixosModules.disko
                      ./sd-image.nix
                    ]
                    ;
                }
                ;

              nixpkgs-overlays =
                {
                  nixpkgs.overlays =
                    let
                      overlay-path = ./.nix/overlays/nixpkgs;
                      dirs = builtins.attrNames (builtins.readDir overlay-path);
                    in
                      map (x: import (overlay-path + ("/" + x))) dirs
                    ;
                }
                ;

              base =
                {
                  imports =
                    with self.modules.nixos;
                    [
                      nixpkgs-overlays
                      raspberry-pi-4-b
                      reterminal-support-layer
                    ]
                    ;
                }
                ;
            }
            ;

          flake.nixosConfigurations.reTerminal =
            inputs.nixos-raspberrypi.lib.nixosSystemFull
              {
                specialArgs = inputs;

                modules =
                  with self.modules.nixos;
                  [
                    base
                    ./configuration.nix
                    sd-image
                    ./trim-packages.nix
                  ]
                  ;
              }
              ;

          perSystem =
            { self', ... }:
            {
              packages =
                {
                  default = self'.packages.sd-image-full;

                  sd-image-full = self.nixosConfigurations.reTerminal.config.system.build.toplevel;
                }
                ;
            }
            ;
        }
      )
      ;
}
