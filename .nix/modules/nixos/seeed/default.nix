{ lib, config, ... }:
let
  devices =
    [
    ]
    ;
in
  {
    imports =
      [
        # ./agx-orin.nix
        # ./bb.nix
        # ./imx6ull.nix
        # ./jetsonnano.nix
        # ./orin-nano.nix
        # ./orin-nx.nix
        ./rpi.nix
        # ./stm32mp1.nix
        # ./stm32mp135.nix
        # ./xavier-nx.nix
      ]
      ;

    options = {};

    config = {};
  }
