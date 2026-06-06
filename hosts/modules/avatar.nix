{userConfig, ...}: {
  # Post-activation script to set user avatar/profile picture
  system.activationScripts.postActivation.text = ''
    # Set user profile picture
    echo "Setting user profile picture for ${userConfig.name}..."
    dscl . delete /Users/${userConfig.name} JPEGPhoto
    dscl . delete /Users/${userConfig.name} Picture
    dscl . create /Users/${userConfig.name} Picture "${toString userConfig.avatar}"
  '';
}
