{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Tmp
  boot.tmp.useTmpfs = true;

  # Power Button behavior
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  # Greeter
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = ''${pkgs.zsh}/bin/zsh -c "${pkgs.sway}/bin/sway"'';
        user = "lucasegp";
      };
      default_session = initial_session;
    };
  };

  # Disable CPU turbo
  systemd.services.cpuNoTurbo = {
    enable = true;
    description = "Disable CPU turbo";
    wantedBy = ["default.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.bash}/bin/bash -c "                                       \
          echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo &&      \
          echo 50 > /sys/devices/system/cpu/intel_pstate/max_perf_pct && \
          echo 10 > /sys/devices/system/cpu/intel_pstate/min_perf_pct    \
        "
      '';
      RemainAfterExit = "yes";
      ExecStop = ''
        ${pkgs.bash}/bin/bash -c "                                        \
          echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo &&       \
          echo 100 > /sys/devices/system/cpu/intel_pstate/max_perf_pct && \
          echo 10 > /sys/devices/system/cpu/intel_pstate/min_perf_pct     \
        "
      '';
    };
  };

  # Swap via zram
  zramSwap.enable = true;

  # Networking
  networking = {
    hostName = "lucasegp-nixos";

    networkmanager = {
      enable = true;
    };
  };

  systemd.services."NetworkManager-wait-online".enable = false;

  programs.wireshark.enable = true;

  # Locale
  time.timeZone = "America/Sao_Paulo";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "br-abnt2";
  };

  # Sound
  sound.enable = true;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Screen
  programs.light.enable = true;
  hardware.opengl.enable = true;
  xdg.portal = {
    enable = true;
    wlr = {
      enable = true;
      settings = {
        screencast = {
          max_fps = 30;
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f %o -or";
        };
      };
    };
    config.common.default = "*";
  };

  # VMs and containers
  programs.virt-manager.enable = true;

  virtualisation = {
    containers.enable = true;

    spiceUSBRedirection.enable = true;

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [
            (pkgs.OVMF.override {
              secureBoot = true;
              tpmSupport = true;
            })
            .fd
          ];
        };
      };
    };

    docker = {enable = true;};
  };

  # Packages
  environment.systemPackages = with pkgs; [
    # Basics
    zsh
    neovim

    # VMs and containers
    docker-compose
    spice-gtk

    # System diagnostics
    htop
    lm_sensors
    nvtopPackages.intel
    wireshark
    pciutils

    # Mass storage utils
    cryptsetup

    # If I mess up the bootloader :)
    efibootmgr
  ];

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # User info
  users.users.lucasegp = {
    isNormalUser = true;
    extraGroups = ["networkmanager" "wheel" "video" "libvirtd" "wireshark"];

    shell = "${pkgs.zsh}/bin/zsh";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.lucasegp = {
      imports = [
        ./home.nix
        inputs.nixvim.homeManagerModules.nixvim
      ];
    };
  };

  # Man pages
  documentation.dev.enable = true;

  # Fonts
  fonts.packages = with pkgs; [(pkgs.nerdfonts.override {fonts = ["Go-Mono"];})];

  # Security
  security.polkit.enable = true;
  security.pam.services.swaylock = {};

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [
      "obsidian"
    ];

  system.stateVersion = "23.11";
}
