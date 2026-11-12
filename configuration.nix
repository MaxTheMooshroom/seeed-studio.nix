{ config, pkgs, ... }:
{
  networking =
    {
      hostName = "reterminal";

      # Configure network connections interactively with nmcli or nmtui.
      networkmanager.enable = true;
    }
    ;

  environment.systemPackages =
    with pkgs;
    [
      neovim
      nano
      wget
      curl
      usbutils
    ]
    ;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # List services that you want to enable:

  services = {
    # Enable sound.
    pipewire = {
      enable = true;
      wireplumber.enable = true;
    };

    xserver.enable = true;

    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;

    openssh.enable = true;
  };

  system = {
    stateVersion = config.system.nixos.release;
  };
}

