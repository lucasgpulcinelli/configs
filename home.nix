{
  config,
  lib,
  pkgs,
  ...
}: {
  # Packages
  home.packages = with pkgs; [
    # Browsers
    librewolf
    ungoogled-chromium
    tor-browser
    vscodium # prove me wrong

    # Office
    obs-studio
    inkscape
    gimp
    libreoffice

    # Gaming
    wineWowPackages.staging
    lutris-free

    # Multimedia
    mpv
    imv
    evince
    ffmpeg
    imagemagick
    graphviz

    # UI stuff
    swaylock
    swaybg
    grim
    slurp
    wl-clipboard
    wl-mirror
    wlsunset

    # Network
    curl
    wget
    lynx
    croc
    tor
    dig

    # Files
    fzf
    ripgrep
    bat
    zip
    unzip
    file
    findutils

    # Security
    gnupg
    pass
    openssl

    # CLI - Fun
    neofetch
    cmatrix

    # Shell Completions
    nix-zsh-completions
    zsh-completions

    # Android
    scrcpy
    android-tools

    # Programming - vcs
    git
    act
    gh

    # Programming - Cloud
    kubectl
    kubectx
    awscli2
    kubernetes-helm
    istioctl

    # Programming - C/C++
    clang
    lld
    cmake
    gnumake
    ninja
    bear
    clang-tools
    perf-tools
    gdb
    valgrind

    # Programming - <Insert Nausea Emoji>
    (pkgs.python310.withPackages (python-pkgs: [
      python-pkgs.pandas
      python-pkgs.numpy
      python-pkgs.matplotlib
    ]))

    # Programming - rust
    rustc
    cargo
    cargo-watch
    rustfmt

    # Programming - other languages
    go
    ghc
    ghcid
    jdk17
    bun
    nodejs_22
  ];

  # System diagostics
  xdg.configFile."htop/htoprc".source = ./extra-configs/htoprc;
  xdg.configFile."btop/themes/btop.theme".source = ./extra-configs/btop.theme;

  programs.btop = {
    enable = true;
    settings = {
      color_theme = "${config.xdg.configHome}/btop/themes/btop.theme";
      theme_background = false;
    };
  };

  # Music player
  programs.mpv = {
    enable = true;
    bindings = {
      "n" = "playlist-next";
      "N" = "playlist-prev";
    };
  };

  # Env vars
  home.sessionVariables = {
    EDITOR = "nvim";
    GTK_THEME = "Adwaita:dark";
  };

  # Window manager
  xdg.configFile."sway-lock.png".source = ./res/lock.png;
  xdg.configFile."sway-bg.png".source = ./res/bg.png;

  wayland.windowManager.sway = let
    green = "#a6e3a1";
    blue = "#89b4fa";
    text = "#cdd6f4";
    surface1 = "#45475a";
    base = "#1e1e2e";
    lock-img = "${config.xdg.configHome}/sway-lock.png";
    bg-img = "${config.xdg.configHome}/sway-bg.png";
  in {
    enable = true;
    checkConfig = false;

    config = rec {
      modifier = "Mod4";
      terminal = "kitty";
      defaultWorkspace = "workspace number 1";

      bars = [
        {
          statusCommand = "${pkgs.i3status}/bin/i3status";
          fonts = {
            names = ["GoMono Nerd Font"];
            size = 15.0;
          };

          colors = {
            background = base;
            statusline = text;
            focusedStatusline = text;
            focusedSeparator = base;
            focusedWorkspace = {
              background = base;
              border = base;
              text = green;
            };
            activeWorkspace = {
              background = base;
              border = base;
              text = blue;
            };
            inactiveWorkspace = {
              background = base;
              border = base;
              text = surface1;
            };
            urgentWorkspace = {
              background = base;
              border = base;
              text = surface1;
            };
            bindingMode = {
              background = base;
              border = base;
              text = surface1;
            };
          };
        }
      ];

      keybindings = lib.mkOptionDefault {
        "XF86AudioMute" = ''
          exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        '';

        "XF86AudioRaiseVolume" = ''
          exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ && \
          wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        '';

        "XF86AudioLowerVolume" = ''
          exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && \
          wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
        '';

        "XF86AudioMicMute" = ''
          exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle &&              \
          dunstify -t 2000 $(                                               \
            wpctl get-volume @DEFAULT_AUDIO_SOURCE@ |                       \
            awk '{if($3) {print("mic muted")} else {print("mic working")}}' \
          )
        '';

        "XF86MonBrightnessUp" = "exec light -A 5";

        "XF86MonBrightnessDown" = "exec light -U 5";

        "Mod4+shift+s" = ''
          exec grim -g "$(slurp)" - | wl-copy --type image/png
        '';

        "Mod4+x" = ''
          exec swaylock -f --image ${lock-img} \
            --indicator-idle-visible &&        \
          systemctl suspend
        '';

        "Mod4+Shift+x" = ''
          exec swaylock -f --image ${lock-img} \
            --indicator-idle-visible
        '';
      };
    };

    extraConfig = let
      lowBatteryScript = pkgs.writeScriptBin "low-battery.sh" ''
        #!/usr/bin/env sh
        while true
        do
          if [[ $(cat /sys/class/power_supply/BAT0/capacity) -le 10 ]] && \
             [[ $(cat /sys/class/power_supply/BAT0/status) = "Discharging" ]]
          then
            dunstify -u critical "Low Battery"
          fi
          sleep 30
        done
      '';
    in ''
      input * {
        xkb_layout "br"
        dwt false
      }

      input type:touchpad {
        tap enabled
        natural_scroll enabled
      }

      default_border none
      output "*" bg ${bg-img} fill

      exec ${lowBatteryScript}/bin/low-battery.sh
    '';
  };

  # Status bar
  programs.i3status = {
    enable = true;
    enableDefault = false;

    modules = {
      "tztime local" = {
        enable = true;
        position = 0;
        settings = {format = "%d/%m/%Y %H:%M ";};
      };
      "wireless wlp0s20f3" = {
        enable = true;
        position = 1;
        settings = {
          format_up = " NET:%quality at %essid ";
          format_down = "NET: down";
        };
      };
      "battery 0" = {
        enable = true;
        position = 2;
        settings = {
          format = " BAT: %percentage %status ";
          format_down = " BAT: none ";
          status_chr = "charging";
          status_bat = "draining";
          status_unk = "unknown";
          status_full = "full";
          last_full_capacity = true;
          path = "/sys/class/power_supply/BAT%d/uevent";
          low_threshold = 20;
        };
      };
      "load" = {
        enable = true;
        position = 3;
        settings = {format = " LOAD: %1min ";};
      };
      "cpu_temperature 0" = {
        enable = true;
        position = 4;
        settings = {
          format = " TEMP: %degrees C ";
          path = "/sys/devices/platform/coretemp.0/hwmon/hwmon?/temp1_input";
        };
      };
      "memory" = {
        enable = true;
        position = 5;
        settings = {
          format = " MEM: %used ";
          threshold_degraded = "25%";
        };
      };
      "volume master" = {
        enable = true;
        position = 6;
        settings = {
          format = " VOL: %volume ";
          format_muted = " VOL: mut %volume ";
          device = "default";
          mixer = "Master";
          mixer_idx = 0;
        };
      };
    };
  };

  # Clipboard manager
  services.cliphist.enable = true;

  # Night light
  services.wlsunset = {
    enable = true;
    temperature.night = 3000;

    # Arbitrary latitude longitude pair set to São Paulo
    # (should have been based on locale but whatever)
    latitude = "-23.55";
    longitude = "-46.63";
  };

  # Notification service
  services.dunst = {
    enable = true;
    settings.global = {font = "GoMono Nerd Font Mono 16";};
  };

  # Shell
  xdg.configFile."zsh-custom/themes/lucasegp.zsh-theme".source =
    ./extra-configs/lucasegp.zsh-theme;

  programs.zsh = {
    enable = true;
    syntaxHighlighting.enable = true;
    syntaxHighlighting.highlighters = ["line" "brackets" "main" "regexp"];

    autosuggestion.enable = true;

    shellAliases = {
      v = "nvim";
      c = "clear";
      k = "kubectl";
      clip = "cliphist list | fzf | cliphist decode | wl-copy";
    };

    oh-my-zsh = {
      enable = true;
      theme = "lucasegp";
      plugins = [
        "git"
        "docker"
        "pass"
        "aws"
        "docker"
        "docker-compose"
        "golang"
        "helm"
        "kubectl"
        "kubectx"
        "pass"
        "python"
        "ripgrep"
        "rsync"
        "tmux"
        "sudo"
        "systemd"
      ];
      custom = "${config.xdg.configHome}/zsh-custom";
    };

    initExtra = ''
      fzcd() {
        dir_to_change=$(              \
          find $@                     \
            -path "*/.git*" -prune -o \
            -path "*/venv*" -prune -o \
            -print                    \
          |fzf --reverse              \
        )

        if [[ -z "$dir_to_change" ]]; then
          return 0
        fi

        if [[ -d "$dir_to_change" ]]; then
          cd "$dir_to_change"
        else
          cd "$(dirname $dir_to_change)"
        fi
      }

      send() {
        croc send --text "$(wl-paste)" --code "$CROC_PASSWORD"
      }

      recv() {
        croc --yes "$CROC_PASSWORD" | wl-copy
      }

      autoload -U compinit; compinit
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      source /home/lucasegp/.extra-zsh-config.sh

      GPG_TTY=$(tty)
      export GPG_TTY
    '';
  };

  # Tmux
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    prefix = "C-Space";
    mouse = true;
    newSession = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "xterm-256color";

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavour 'mocha'
        '';
      }
      sensible
      yank
      vim-tmux-navigator
    ];

    extraConfig = ''
      bind -n C-h select-pane -L
      bind -n C-j select-pane -D
      bind -n C-k select-pane -U
      bind -n C-l select-pane -R
      bind u send-keys "\003\012fzcd ~\012"
      bind i send-keys "\003\012clear\012"
      bind o send-keys "\003\012clip\012"

      set -g status-bg 'default'
      set-option -g status-style bg=default
      set-option -sa terminal-overrides ",xterm*:Tc"

      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel

      bind-key a swap-window -t -1 \; select-window -t -1
      bind-key d swap-window -t +1 \; select-window -t +1

      bind ';' split-window -v -c "#{pane_current_path}"
      bind 'ç' split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
    '';
  };

  # Editor
  programs.nixvim = {
    enable = true;
    opts = {
      number = true;
      relativenumber = true;
      confirm = true;
      shiftwidth = 2;
      expandtab = true;
      softtabstop = 0;
      tabstop = 2;
      undofile = false;
      smartcase = true;
      ignorecase = true;
      colorcolumn = "80";
      foldmethod = "indent";
      foldlevelstart = 10;
    };

    globals = {mapleader = " ";};

    keymaps = [
      {
        key = "<C-d>";
        action = "<C-d>zz";
        options.noremap = true;
        options.desc = "Half page down";
      }
      {
        key = "<C-u>";
        action = "<C-u>zz";
        options.noremap = true;
        options.desc = "Half page up";
      }
      {
        key = "n";
        action = "nzz";
        options.noremap = true;
        options.desc = "Next item";
      }
      {
        key = "N";
        action = "Nzz";
        options.noremap = true;
        options.desc = "Prev item";
      }
      {
        key = "{<CR>";
        action = "{<CR>}<ESC>O";
        mode = ["i"];
        options.noremap = true;
      }
      {
        key = "<Leader>s";
        action = "<cmd>%s/\\s\\+$/<CR>";
        options.noremap = true;
        options.desc = "Remove dangling whitespaces";
      }
      {
        key = "<Leader>d";
        action = ''"+d'';
        mode = ["n" "v"];
        options.noremap = true;
        options.desc = "Delete and put contents in system clipboard";
      }
      {
        key = "<Leader>c";
        action = ''"+c'';
        mode = ["n" "v"];
        options.noremap = true;
        options.desc = "Cut and put contents in system clipboard";
      }
      {
        key = "p";
        action = ''"+P'';
        mode = ["n" "v"];
        options.noremap = true;
        options.desc = "Paste and throw away highlighted contents";
      }
      {
        key = "y";
        action = ''"+y'';
        mode = ["n" "v"];
        options.noremap = true;
        options.desc = "Yank contents to system clipboard";
      }
      {
        key = "<Tab>";
        action = "<cmd>bn<CR>";
        options.noremap = true;
        options.desc = "Buffer next";
      }
      {
        key = "<S-Tab>";
        action = "<cmd>bp<CR>";
        options.noremap = true;
        options.desc = "Buffer prev";
      }
      {
        key = "<Leader>x";
        action = "<cmd>bd<CR>";
        options.noremap = true;
        options.desc = "Buffer delete";
      }
      {
        key = "<Leader>f";
        action = "<cmd> Telescope find_files <CR>";
        options.noremap = true;
        options.desc = "Fuzzy find files";
      }
      {
        key = "<Leader>b";
        action = "<cmd> Telescope current_buffer_fuzzy_find <CR>";
        options.noremap = true;
        options.desc = "Fuzzy find inside buffer";
      }
      {
        key = "<Leader>n";
        action = "<cmd> NvimTreeToggle <CR>";
        options.noremap = true;
        options.desc = "Toggle NvimTree";
      }
      {
        key = "<Leader>u";
        action = "<cmd> UndotreeToggle <CR><cmd> UndotreeFocus <CR>";
        options.noremap = true;
        options.desc = "Toggle UndoTree";
      }
      {
        key = "<Leader>gs";
        action = "<cmd> Gitsigns stage_hunk <CR>";
        options.noremap = true;
        options.desc = "Git stage hunk";
      }
      {
        key = "<Leader>gu";
        action = "<cmd> Gitsigns undo_stage_hunk <CR>";
        options.noremap = true;
        options.desc = "Git undo stage";
      }
      {
        key = "<Leader>gd";
        action = "<cmd> Gitsigns diffthis <CR>";
        options.noremap = true;
        options.desc = "Git diff";
      }
      {
        key = "<Leader>gn";
        action = "<cmd> Gitsigns next_hunk <CR>";
        options.noremap = true;
        options.desc = "Git next hunk";
      }
      {
        key = "<Leader>gp";
        action = "<cmd> Gitsigns prev_hunk <CR>";
        options.noremap = true;
        options.desc = "Git prev hunk";
      }
      {
        key = "<Leader>lf";
        action = "<cmd> lua vim.lsp.buf.format() <CR>";
        options.noremap = true;
        options.desc = "LSP format";
      }
      {
        key = "<Leader>la";
        action = "<cmd> lua vim.lsp.buf.code_action() <CR>";
        options.noremap = true;
        options.desc = "LSP code action";
      }
      {
        key = "<Leader>ldc";
        action = "<cmd> lua vim.lsp.buf.declaration() <CR>";
        options.noremap = true;
        options.desc = "LSP declaration";
      }
      {
        key = "<Leader>ldf";
        action = "<cmd> lua vim.lsp.buf.definition() <CR>";
        options.noremap = true;
        options.desc = "LSP definition";
      }
      {
        key = "<Leader>li";
        action = "<cmd> lua vim.lsp.buf.implementation() <CR>";
        options.noremap = true;
        options.desc = "LSP implementation";
      }
      {
        key = "<Leader>lr";
        action = "<cmd> lua vim.lsp.buf.references() <CR>";
        options.noremap = true;
        options.desc = "LSP references";
      }
      {
        key = "<Leader>ln";
        action = "<cmd> lua vim.lsp.buf.rename() <CR>";
        options.noremap = true;
        options.desc = "LSP rename";
      }
      {
        key = "<Leader>lh";
        action = "<cmd> lua vim.lsp.buf.signature_help() <CR>";
        options.noremap = true;
        options.desc = "LSP signature help";
      }
    ];

    colorschemes.catppuccin = {
      enable = true;
      settings = {
        term_colors = true;
        flavour = "mocha";
        transparent_background = true;
      };
    };

    plugins = {
      tmux-navigator.enable = true;
      lualine.enable = true;
      bufferline.enable = true;
      which-key.enable = true;
      telescope.enable = true;
      undotree.enable = true;
      gitsigns.enable = true;
      nvim-tree = {
        enable = true;
        openOnSetup = true;
      };
      luasnip.enable = true;
      treesitter-context = {
        enable = true;
        settings.on_attach = ''
          function(buf)
            vim.api.nvim_set_hl(
              0,
              'TreesitterContextBottom',
              { underline=true, fg="darkgrey", bg="none" }
            )
            vim.api.nvim_set_hl(
              0,
              'TreesitterContext',
              { bg="none" }
            )
            return true
          end
        '';
      };
      treesitter = {
        enable = true;
        ensureInstalled = [
          "c"
          "cpp"
          "go"
          "gomod"
          "gosum"
          "python"
          "lua"
          "nix"
          "bash"
          "dockerfile"
          "markdown"
          "json"
          "yaml"
        ];
      };
      lsp = {
        enable = true;
        servers = {
          gopls.enable = true;
          clangd.enable = true;
          ruff-lsp.enable = true;
          tsserver.enable = true;
        };

        onAttach = ''
          vim.api.nvim_set_hl(
            0,
            'NormalFloat',
            { bg="#313244" }
          )
        '';
      };
      cmp = {
        enable = true;
        settings = {
          sources = [
            {name = "nvim_lsp";}
            {name = "path";}
            {name = "buffer";}
            {name = "luasnip";}
          ];

          mapping = {
            "<CR>" = "cmp.mapping.confirm({ select = true })";
            "<S-Tab>" = ''
              function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip == nil then
                  fallback()
                elseif luasnip.expandable() then
                  luasnip.expand()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                elseif check_backspace() then
                  fallback()
                else
                  fallback()
                end
              end
            '';
            "<Tab>" = ''
              function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                elseif luasnip == nil then
                  fallback()
                elseif luasnip.expandable() then
                  luasnip.expand()
                elseif luasnip.expand_or_jumpable() then
                  luasnip.expand_or_jump()
                elseif check_backspace() then
                  fallback()
                else
                  fallback()
                end
              end
            '';
          };

          snippet.expand = ''
            function(args)
              require('luasnip').lsp_expand(args.body)
            end
          '';
        };
      };
    };
  };

  # Terminal
  programs.kitty = {
    enable = true;
    theme = "Catppuccin-Mocha";
    font = {
      name = "GoMono Nerd Font Mono";
      size = 15;
    };
    settings = {
      shell = "tmux attach";
      enable_audio_bell = false;
      background_opacity = "0.95";
      cursor_shape = "block";
    };
  };

  # Git
  programs.git = {
    enable = true;
    extraConfig = {
      user = {
        name = "lucasgpulcinelli";
        email = "lucasegp@usp.br";
        signingKey = "90D299F3B08FE60D";
      };
      init = {defaultBranch = "main";};
      commit = {gpgsign = true;};
    };
  };

  # Gpg agent
  services.gpg-agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    defaultCacheTtl = 600;

    enableSshSupport = true;
    defaultCacheTtlSsh = 600;
  };

  home.stateVersion = "23.11";
}
