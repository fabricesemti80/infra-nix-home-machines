# Module: CoreCtrl Hardware Control
# Purpose: Configures CoreCtrl for GPU overclocking and hardware monitoring
# Platform: NixOS only (AMD GPU)
_: {
  programs.corectrl = {
    enable = true;
    gpuOverclock = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };

  # Allow CoreCtrl to run without password prompt
  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if ((action.id == "org.corectrl.helper.init" ||
          action.id == "org.corectrl.helperkiller.init") &&
          subject.local == true &&
          subject.active == true &&
          subject.isInGroup("users")) {
        return polkit.Result.YES;
      }
    });
  '';
}
