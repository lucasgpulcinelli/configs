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
    brave
    tor-browser

    # Office
    obs-studio
    inkscape
    gimp
    kdePackages.kdenlive
    obsidian

    # Gaming
    wineWowPackages.staging
    lutris-free
    prismlauncher

    # Multimedia
    mpv
    imv
    evince
    ffmpeg
    imagemagick
    graphviz
    yt-dlp
    poppler_utils
    usbutils

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
    traceroute

    # Files
    fzf
    zip
    unzip
    file
    findutils
    jq

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
      python-pkgs.seaborn
    ]))

    # Programming - rust
    rustc
    cargo
    cargo-watch
    rustfmt

    # Programming - other languages
    go
    graalvm-ce
    bun
    nodejs_22
    sqlite
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
    JAVA_HOME = "${pkgs.graalvm-ce}";
  };

  home.sessionPath = ["$HOME/.local/bin"];

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

      keybindings = let
        lightScript = pkgs.writeScriptBin "light-script.sh" ''
          #!/usr/bin/env sh

          l=$(light -G)
          f=1.2

          if [[ $1 = "up" ]]; then
            l=$(echo "$l $f" | awk '{print($1 * $2)}')
          else
            l=$(echo "$l $f" | awk '{print($1 / $2)}')
          fi

          light -S $l
        '';
      in
        lib.mkOptionDefault {
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

          "XF86MonBrightnessUp" = "exec ${lightScript}/bin/light-script.sh up";

          "XF86MonBrightnessDown" = "exec ${lightScript}/bin/light-script.sh down";

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
        croc send --text "$(wl-paste)"
      }

      recv() {
        croc --yes | wl-copy
      }

      autoload -U compinit; compinit
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      source /home/lucasegp/.extra-zsh-config.sh

      GPG_TTY=$(tty)
      export GPG_TTY

      eval "$(direnv hook zsh)"
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
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind o send-keys "\003\012fzcd ~\012"
      bind i send-keys "\003\012clear\012"
      bind u send-keys "\003\012clip\012"

      set -g status-bg 'default'
      set-option -g status-style bg=default
      set-option -sa terminal-overrides ",xterm*:Tc"
      set-option -g renumber-windows on

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
        key = "K";
        action = ":m '<-2<CR>gv=gv";
        options.noremap = true;
        mode = ["v"];
      }
      {
        key = "J";
        action = ":m '>+1<CR>gv=gv";
        options.noremap = true;
        mode = ["v"];
      }
      {
        key = "<Leader>x";
        action = "<cmd>bd<CR>";
        options.noremap = true;
        options.desc = "Buffer delete";
      }
      {
        key = "<Leader>ff";
        action = "<cmd> Telescope find_files <CR>";
        options.noremap = true;
        options.desc = "Fuzzy find files";
      }
      {
        key = "<Leader>fg";
        action = "<cmd> Telescope live_grep <CR>";
        options.noremap = true;
        options.desc = "Live Grep";
      }
      {
        key = "<Leader>ft";
        action = "<cmd> NvimTreeToggle <CR>";
        options.noremap = true;
        options.desc = "Toggle NvimTree";
      }
      {
        key = "<Leader>fu";
        action = "<cmd> UndotreeToggle <CR><cmd> UndotreeFocus <CR>";
        options.noremap = true;
        options.desc = "Toggle UndoTree";
      }
      {
        key = "<Leader>ga";
        action = "<cmd> Gitsigns stage_hunk <CR>";
        options.noremap = true;
        options.desc = "Git add hunk";
        mode = ["n" "v"];
      }
      {
        key = "<Leader>gu";
        action = "<cmd> Gitsigns undo_stage_hunk <CR>";
        options.noremap = true;
        options.desc = "Git undo add";
      }
      {
        key = "<Leader>gd";
        action = "<cmd> Gitsigns diffthis <CR>";
        options.noremap = true;
        options.desc = "Git diff";
      }
      {
        key = "<Leader>gn";
        action = "<cmd> Gitsigns next_hunk <CR>zz";
        options.noremap = true;
        options.desc = "Git next hunk";
      }
      {
        key = "<Leader>gp";
        action = "<cmd> Gitsigns prev_hunk <CR>zz";
        options.noremap = true;
        options.desc = "Git prev hunk";
      }
      {
        key = "<Leader>gb";
        action = "<cmd> Gitsigns blame_line <CR>";
        options.noremap = true;
        options.desc = "Git blame line";
      }
      {
        key = "<C-f>";
        action = "<cmd> lua vim.lsp.buf.format() <CR>";
        options.noremap = true;
        options.desc = "LSP format";
      }
      {
        key = "gd";
        action = "<cmd> lua vim.lsp.buf.definition() <CR>";
        options.noremap = true;
        options.desc = "LSP definition";
      }
      {
        key = "gc";
        action = "<cmd> lua vim.lsp.buf.declaration() <CR>";
        options.noremap = true;
        options.desc = "LSP declaration";
      }
      {
        key = "gr";
        action = "<cmd> lua vim.lsp.buf.references() <CR>";
        options.noremap = true;
        options.desc = "LSP references";
      }
      {
        key = "K";
        action = "<cmd> lua vim.lsp.buf.hover() <CR>";
        options.noremap = true;
        options.desc = "LSP hover";
        mode = ["n"];
      }
      {
        key = "<C-h>";
        action = "<cmd> lua vim.lsp.buf.signature_help() <CR>";
        options.noremap = true;
        options.desc = "LSP signature help";
        mode = ["i"];
      }
      {
        key = "<Leader>la";
        action = "<cmd> lua vim.lsp.buf.code_action() <CR>";
        options.noremap = true;
        options.desc = "LSP code action";
      }
      {
        key = "<Leader>ln";
        action = "<cmd> lua vim.lsp.buf.rename() <CR>";
        options.noremap = true;
        options.desc = "LSP rename";
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
      nvim-tree.enable = true;
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
          pyright.enable = true;
          tsserver.enable = true;
          elixirls.enable = true;
          rust-analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
        };

        onAttach = ''
          vim.api.nvim_set_hl(
            0,
            'NormalFloat',
            { bg="#313244" }
          )
        '';
      };
      nvim-jdtls = {
        enable = true;
        data = "${config.xdg.cacheHome}/jdtls/workspace";
        configuration = "${config.xdg.cacheHome}/jdtls/config";
      };
      copilot-chat.enable = true;
      copilot-cmp.enable = true;
      copilot-lua = {
        enable = true;
        panel.enabled = false;
        suggestion.enabled = false;
      };
      cmp = {
        enable = true;
        settings = {
          sources = [
            {name = "copilot";}
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

    autoCmd = [
      {
        command = "Copilot disable";
        event = [
          "VimEnter"
        ];
      }
    ];
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
    pinentryPackage = pkgs.pinentry-qt;
    defaultCacheTtl = 600;

    enableSshSupport = true;
    defaultCacheTtlSsh = 600;
  };

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  home.stateVersion = "23.11";
}
