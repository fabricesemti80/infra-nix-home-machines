{userConfig, ...}: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # NOTE: cleanup is deprecated in Homebrew 4.0+ — use `brew bundle cleanup` manually
      cleanup = "none";
      upgrade = true;
    };

    # Homebrew Additional Repositories (kept for casks)
    taps = [
      "nikitabobko/tap"
      "powershell/tap"
      "Adembc/homebrew-tap"
      # "manaflow-ai/cmux"
      "matt-wright86/homebrew-tap"
    ];

    brews = [
      "beads" # Memory upgrade for your coding agent - https://gastownhall.github.io/beads/community-tools
    ];

    casks = [
      #* AI Tools
      "claude" # Claude AI client
      "claude-code" # Claude CLI
      # "chatgpt" # ChatGPT desktop client
      # "kiro" # AI editor
      "antigravity-cli" # Google Antigravity CLI (agy) - Gemini CLI replacement
      # "ollama-app" # Local AI model manager and runner
      # "block-goose" # AI coding agent
      # "cmux" # AI terminal multiplexer
      "codex" # Codex desktop client
      "claudebar"
      "cursor" # AI editor
      # "block-goose" # AI coding assistant
      "lm-studio" # Local AI model runner and chat interface
      "opencode-desktop"

      #* Authentication & Security
      "1password" # Secure password manager
      "1password-cli" # Command-line interface for 1Password

      #* 3D Printing
      # "autodesk-fusion"
      "bambu-studio" # 3D printer
      # "openscad@snapshot"
      # "blender"

      #* Productivity & Utilities
      # "rectangle"
      # "tolaria"
      "fliqlo" # Digital clock screensaver
      # "keycastr"
      # "hyperkey"
      "keyclu"
      "numi" # Calculator and unit converter
      # "shottr"
      "appcleaner" # Thorough app uninstaller
      # "tailscale" #! installed from App Store
      "wifiman"
      "clop" # Clipboard manager
      # "disk-inventory-x"
      "daisydisk" # Disk space analyzer
      # "transmission"

      #* DevOps & Containers
      # "headlamp"
      "freelens" # Kubernetes IDE (OpenLens)
      "orbstack" # Fast, lightweight Docker alternative
      # "vagrant"

      #* Virtualization
      "citrix-workspace" # Client for virtual desktops

      #* Display & Graphics
      "ddpm" # Dell Display and Peripheral Manager
      # "displaylink" # Driver for USB display adapters

      #* System Enhancements
      "aerospace" # Tiling window manager for macOS
      "commander-one" # Dual-pane file manager
      "raycast" # Spotlight replacement and productivity launcher
      "stats" # System monitoring tool for macOS menubar

      #* Development Tools
      "obsidian" # Knowledge base and note-taking tool
      # "logseq"
      "powershell" # Cross-platform automation tool
      "termius" # Cross-platform SSH client and terminal
      "visual-studio-code" # Code editor
      # "zed"
      "pycharm" # IDE for Python development
      # "ghostty"
      "warp" # Modern terminal with AI features

      #* Browsers & Communication
      # "vivaldi"
      "discord" # Communication platform
      "brave-browser" # Privacy-focused web browser
      "netdownloadhelpercoapp"
      "telegram" # Messaging application
      "whatsapp" # Secure messaging application
      # "zen-browser"
      "microsoft-teams"

      #* Media Players
      "capcut" # Video editor
      "iina" # Modern media player for macOS

      #* Gaming
      # "steam"

      #* Fonts
      "font-hack-nerd-font" # Developer-oriented font with programming glyphs

      #* Database Tools
      "beekeeper-studio" # Modern SQL client
    ];
  };

  system.activationScripts.postActivation.text = ''
    find /Applications -maxdepth 1 -type d -name "*.app" -exec xattr -dr com.apple.quarantine {} + 2>/dev/null || true

    ddpm_app="/Applications/DDPM/DDPM.app"
    ddpm_root="/Applications/DDPM"
    ddpm_user="/Users/${userConfig.name}/Applications/DDPM"

    if [ -x "$ddpm_app/Contents/MacOS/DDPM" ]; then
      echo "Repairing DDPM install state..."

      install -d -o ${userConfig.name} -g staff -m 755 "$ddpm_user"

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
      copy_if_missing "$ddpm_app/Contents/Resources/DDPM_settings.json" "$ddpm_user/DDPM_settings.json" ${userConfig.name} staff 644
      copy_if_missing "$ddpm_app/Contents/Resources/DDPM_Camera_Settings.json" "$ddpm_user/DDPM_Camera_Settings.json" ${userConfig.name} staff 644
      copy_if_missing "$ddpm_app/Contents/Resources/DDPM_CapabilityString.json" "$ddpm_user/DDPM_CapabilityString.json" ${userConfig.name} staff 644

      if [ ! -f "$ddpm_user/SW_VER.json" ]; then
        version="$(defaults read "$ddpm_app/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo unknown)"
        printf '{\n    "SW_VER": "%s"\n}\n' "$version" > "$ddpm_user/SW_VER.json"
        chown ${userConfig.name}:staff "$ddpm_user/SW_VER.json"
        chmod 644 "$ddpm_user/SW_VER.json"
      fi
    fi
  '';
}
