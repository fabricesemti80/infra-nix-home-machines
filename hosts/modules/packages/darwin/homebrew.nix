{userConfig, ...}: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      cleanup = "none";
      upgrade = false;
    };

    brews = [
      "beads" # Memory upgrade for your coding agent - https://github.com/gastownhall/beads
      # ponytail: opencode moved to nixpkgs (system.nix) - brew upgrade needs Xcode 27 on macOS 27
    ];

    casks = [
      #* AI Tools
      "claude" # Claude AI client — https://claude.com/download
      "claude-code" # Claude CLI — https://claude.com/product/claude-code
      # "chatgpt" # ChatGPT desktop client — https://chatgpt.com/
      # "kiro" # AI editor — https://kiro.dev/
      "antigravity-cli" # Google Antigravity CLI (agy); Homebrew is its sole owner.
      # "ollama-app" # Local AI model manager and runner — https://ollama.com/
      # "block-goose" # AI coding agent — https://block.github.io/goose/
      # "cmux" # AI terminal multiplexer — https://www.cmux.dev/
      "cursor" # AI editor — https://www.cursor.com/
      "xiufengsun/tokentracker/tokentracker" # Token usage & cost tracker menu bar app — https://github.com/xiufengsun/tokentracker
      # "block-goose" # AI coding assistant — https://block.github.io/goose/
      "lm-studio" # Local AI model runner and chat interface — https://lmstudio.ai/
      "opencode-desktop" # https://opencode.ai/

      #* Authentication & Security
      "1password" # Secure password manager — https://1password.com/
      "1password-cli" # Command-line interface for 1Password — https://developer.1password.com/docs/cli

      #* 3D Printing
      # "autodesk-fusion" # https://www.autodesk.com/products/fusion-360/overview
      "bambu-studio" # 3D printer — https://bambulab.com/en/download/studio
      # "openscad@snapshot" # https://www.openscad.org/downloads.html#snapshots
      # "blender" # https://www.blender.org/

      #* Productivity & Utilities
      # "rectangle" # https://rectangleapp.com/
      # "tolaria" # https://tolaria.md/
      "fliqlo" # Digital clock screensaver — https://fliqlo.com/
      # "keycastr" # https://github.com/keycastr/keycastr
      # "hyperkey" # https://hyperkey.app/
      "keyclu" # https://sergii.tatarenkov.name/apps/keyclu/
      "logi-options+" # Logitech MX Master 3 button and scrolling settings — https://www.logitech.com/software/logi-options-plus.html
      "notion" # Workspace and note-taking app — https://www.notion.com/
      "numi" # Calculator and unit converter — https://numi.app/
      # "shottr" # https://shottr.cc/
      "appcleaner" # Thorough app uninstaller — https://freemacsoft.net/appcleaner/
      # "tailscale" #! installed from App Store — https://tailscale.com/
      "wifiman" # https://wifiman.com/
      "clop" # Clipboard manager — https://lowtechguys.com/clop/
      # "disk-inventory-x" # https://www.derlien.com/
      "daisydisk" # Disk space analyzer — https://daisydiskapp.com/
      # "transmission" # https://transmissionbt.com/

      #* DevOps & Containers
      # "headlamp" # https://headlamp.dev/
      "freelens" # Kubernetes IDE (OpenLens) — https://freelens.app/
      "orbstack" # Fast, lightweight Docker alternative — https://orbstack.dev/
      # "vagrant" # https://www.vagrantup.com/

      #* Virtualization
      "citrix-workspace" # Client for virtual desktops — https://docs.citrix.com/en-us/citrix-workspace

      #* Display & Graphics
      "ddpm" # Dell Display and Peripheral Manager — https://www.dell.com/support/kbdoc/en-uk/000214454/dell-display-and-peripheral-manager-for-macos
      # "displaylink" # Driver for USB display adapters — https://www.synaptics.com/products/displaylink-graphics

      #* System Enhancements
      "commander-one" # Dual-pane file manager — https://mac.eltima.com/file-manager.html
      "raycast" # Spotlight replacement and productivity launcher — https://raycast.com/
      "stats" # System monitoring tool for macOS menubar — https://github.com/exelban/stats

      #* Development Tools
      "obsidian" # Knowledge base and note-taking tool — https://obsidian.md/
      # "logseq" # https://github.com/logseq/logseq
      "powershell" # Cross-platform automation tool — https://learn.microsoft.com/powershell/
      "termius" # Cross-platform SSH client and terminal — https://www.termius.com/
      "visual-studio-code" # Code editor — https://code.visualstudio.com/
      # "zed" # https://zed.dev/
      "pycharm" # IDE for Python development — https://www.jetbrains.com/pycharm/
      "ghostty" # GPU-accelerated terminal emulator — https://ghostty.org/
      "warp" # Modern terminal with AI features — https://www.warp.dev/terminal

      #* Browsers & Communication
      # "vivaldi" # https://vivaldi.com/
      "discord" # Communication platform — https://discord.com/
      "brave-browser" # Privacy-focused web browser — https://brave.com/
      "netdownloadhelpercoapp" # https://www.downloadhelper.net/w/CoApp-Installation
      "telegram" # Messaging application — https://macos.telegram.org/
      "whatsapp" # Secure messaging application — https://www.whatsapp.com/
      # "zen-browser" # https://zen-browser.app/
      "microsoft-teams" # https://www.microsoft.com/en/microsoft-teams/group-chat-software/

      #* Media Players
      "capcut" # Video editor — https://www.capcut.com/
      "iina" # Modern media player for macOS — https://iina.io/

      #* Gaming
      # "steam" # https://store.steampowered.com/about/
      "moonlight" # Game-streaming client — https://moonlight-stream.org/

      #* Fonts
      "font-hack-nerd-font" # Developer-oriented font with programming glyphs — https://www.nerdfonts.com/

      #* Database Tools
      "beekeeper-studio" # Modern SQL client — https://www.beekeeperstudio.io/
    ];
  };

  system.activationScripts.postActivation.text = ''
    ddpm_app="/Applications/DDPM/DDPM.app"
    ddpm_root="/Applications/DDPM"
    ddpm_user="/Users/${userConfig.name}/Applications/DDPM"

    if [ -x "$ddpm_app/Contents/MacOS/DDPM" ]; then
      echo "Repairing DDPM install state..."

      copy_if_missing() {
        src="$1"
        dst="$2"
        owner="$3"
        group="$4"
        mode="$5"

        if [ ! -e "$dst" ] && [ -f "$src" ]; then
          install -o "$owner" -g "$group" -m "$mode" "$src" "$dst"
        fi
      }

      helper_src="$ddpm_app/Contents/Library/LaunchServices/com.DDPM.Helper"
      helper_dst="/Library/PrivilegedHelperTools/com.DDPM.Helper"
      if [ -f "$helper_src" ] && ! cmp -s "$helper_src" "$helper_dst"; then
        install -o root -g wheel -m 755 "$helper_src" "$helper_dst"
      fi

      plist_src="$ddpm_app/Contents/Resources/SMJobBlessHelper-Launchd.plist"
      plist_dst="/Library/LaunchDaemons/com.DDPM.Helper.plist"
      if [ -f "$plist_src" ] && ! cmp -s "$plist_src" "$plist_dst"; then
        install -o root -g wheel -m 644 "$plist_src" "$plist_dst"
      fi

      if [ -f "$plist_dst" ] && ! launchctl print system/com.DDPM.Helper >/dev/null 2>&1; then
        launchctl bootstrap system "$plist_dst" || true
      fi

      copy_if_missing "$ddpm_app/Contents/Resources/DDPM_settings.json" "$ddpm_root/DDPM_settings_AllUser.json" root staff 666
      copy_if_missing "$ddpm_app/Contents/Resources/DDPM_Marketing_Name.json" "$ddpm_root/DDPM_Marketing_Name.json" root staff 644

      version="$(defaults read "$ddpm_app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo unknown)"
      /usr/bin/sudo -u ${userConfig.name} /bin/sh -s -- "$ddpm_app" "$ddpm_user" "$version" <<'DDPM_USER_SETUP'
      set -eu
      umask 022
      app="$1"
      user_dir="$2"
      version="$3"
      /bin/mkdir -p "$user_dir"

      copy_if_missing() {
        src="$1"
        dst="$2"
        mode="$3"
        if [ ! -e "$dst" ] && [ -f "$src" ]; then
          /usr/bin/install -m "$mode" "$src" "$dst"
        fi
      }

      copy_if_missing "$app/Contents/Resources/DDPM_settings.json" "$user_dir/DDPM_settings.json" 644
      copy_if_missing "$app/Contents/Resources/DDPM_Camera_Settings.json" "$user_dir/DDPM_Camera_Settings.json" 644
      copy_if_missing "$app/Contents/Resources/DDPM_CapabilityString.json" "$user_dir/DDPM_CapabilityString.json" 644

      if [ ! -f "$user_dir/SW_VER.json" ]; then
        printf '{\n    "SW_VER": "%s"\n}\n' "$version" > "$user_dir/SW_VER.json"
      fi
    DDPM_USER_SETUP
    fi
  '';
}
