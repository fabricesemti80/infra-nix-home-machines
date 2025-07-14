{
  pkgs,
  outputs,
  userConfig,
  ...
}: {
  imports = [
    # Shared Mac apps and configs
    ../modules/avatar.nix
    ../modules/mac-common.nix

    # Specific app to this device
    # ../modules/jankyborders.nix
    # ../modules/sketchybar.nix
    ../modules/parallels.nix
  ];

  # Homebrew package manager configuration for macOS
  nix-homebrew = {
    enable = true;
    enableRosetta = true; # Enable support for Intel-based apps on Apple Silicon
    user = "${userConfig.name}";
    autoMigrate = true; # Automatically migrate existing Homebrew installations
  };

  # Configure nixpkgs behavior and overlays
  nixpkgs = {
    overlays = [
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true; # Allow installation of non-free packages
    };
  };

  # Configure Nix package manager behavior
  nix.settings = {
    experimental-features = "nix-command flakes"; # Enable flakes and new CLI features
  };
  nix.optimise.automatic = true; # Automatically optimize nix store
  nix.package = pkgs.nix; # Use the nix package from pkgs

  # # Enable the Nix daemon service
  # services.nix-daemon.enable = true;

  # Configure the user account
  users.users.${userConfig.name} = {
    name = "${userConfig.name}";
    home = "/Users/${userConfig.name}";
  };

  # Enable TouchID authentication for sudo commands
  security.pam.services.sudo_local.touchIdAuth = true;

  # System-wide macOS settings and preferences - https://daiderd.com/nix-darwin/manual/index.html
  system = {
    # Various macOS default settings
    defaults = {
      # Global mouse settings
      ".GlobalPreferences" = {
        # "com.apple.mouse.scaling" = -1.0; # Disable mouse acceleration
      };

      # Global system preferences
      NSGlobalDomain = {
        AppleInterfaceStyle = "Dark"; # Enable dark mode
        ApplePressAndHoldEnabled = false; # Disable press-and-hold for keys
        AppleShowAllExtensions = true; # Show all file extensions
        KeyRepeat = 2; # Fast key repeat rate
        # Disable various automatic text features
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticWindowAnimationsEnabled = false;
        NSDocumentSaveNewDocumentsToCloud = false;
        NSNavPanelExpandedStateForSaveMode = true;
        PMPrintingExpandedStateForPrint = true;
      };

      # Launch Services preferences
      LaunchServices = {
        LSQuarantine = false; # Disable quarantine for downloaded apps
      };

      # Trackpad settings
      trackpad = {
        TrackpadRightClick = true; # Enable two-finger right click
        TrackpadThreeFingerDrag = true; # Enable three-finger drag
        Clicking = true; # Enable tap to click
      };

      # Finder preferences
      finder = {
        AppleShowAllFiles = true; # Show hidden files
        CreateDesktop = false; # Hide desktop icons
        FXDefaultSearchScope = "SCcf"; # Search current folder by default
        FXEnableExtensionChangeWarning = false; # Disable extension change warning
        FXPreferredViewStyle = "Nlsv"; # List view by default
        QuitMenuItem = true; # Allow quitting Finder
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXShowPosixPathInTitle = true; # Show full path in Finder title
        _FXSortFoldersFirst = true; # Sort folders before files

        # Remove items after 30 days
        FXRemoveOldTrashItems = true;

        # Change the default folder shown in Finder windows.
        # “Other” corresponds to the value of NewWindowTargetPath. The default is unset (“Recents”). Type: null or one of “Computer”, “OS volume”, “Home”, “Desktop”, “Documents”, “Recents”, “iCloud Drive”, “Other”
        NewWindowTarget = "Home";
      };

      # Dock preferences
      dock = {
        orientation = "right";
        autohide = true; # Automatically hide the dock
        expose-animation-duration = 0.15;
        show-recents = false; # Don't show recent applications
        showhidden = true; # Show indicator for hidden applications
        persistent-apps = [
          # Apps that persist in the dock
          "com.vivaldi.Vivaldi"
          # "/Applications/Brave Browser.app"
          "/Applications/Commander One.app"
          # "/Applications/Zen Browser.app" # brew
          # "/Applications/Zen.app" # app store
          # "/Applications/OrbStack.app"
          # "/Applications/Ghostty.app"
          # "/Applications/Warp.app"
          # "/Applications/Visual Studio Code"
          # "/Applications/Parallels Desktop.app"

          # ## Home Manager packages
          "${pkgs.vscode}/Applications/Visual Studio Code.app"
          # "${pkgs.obsidian}/Applications/Obsidian.app"
        ];
        tilesize = 60; # Dock icon size
        # Disable hot corners
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
      };

      # Screenshot preferences
      screencapture = {
        location = "/Users/${userConfig.name}/Downloads/temp"; # Screenshot save location
        type = "png"; # Screenshot format
        disable-shadow = true; # Disable window shadows in screenshots
      };

      # Menu bar
      menuExtraClock = {
        Show24Hour = true;
      };
    };

    # Keyboard settings
    keyboard = {
      enableKeyMapping = true;
      userKeyMapping = [
        {
          # Remap §± key to ~
          HIDKeyboardModifierMappingDst = 30064771125;
          HIDKeyboardModifierMappingSrc = 30064771172;
        }
      ];
    };

    # Declare primary user
    primaryUser = "${userConfig.name}";
  };

  # Post-activation script to set custom keyboard shortcuts
  system.activationScripts.postActivation.text = ''
    # Set Spotlight shortcut to Option + Space
    # Parameters explanation:
    # 32 = Space key
    # 49 = key code for space
    # 524288 = Option key modifier
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 "
      <dict>
        <key>enabled</key><true/>
        <key>value</key><dict>
          <key>type</key><string>standard</string>
          <key>parameters</key>
          <array>
            <integer>32</integer>
            <integer>49</integer>
            <integer>524288</integer>
          </array>
        </dict>
      </dict>
    "
  '';


  # Enable Zsh as the default shell
  programs.zsh.enable = true;

  # Install system fonts
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.meslo-lg
    roboto
  ];

  # Set hostname
  networking.hostName = "macpro-fs";

  # System state version (for backwards compatibility)
  system.stateVersion = 5;
}
