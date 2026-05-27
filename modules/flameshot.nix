{ pkgs, ... }:

let
  flameshot = pkgs.flameshot;
in
{
  environment.systemPackages = [
    flameshot
  ];

  # Keep Flameshot's primary app process alive. Copy-to-clipboard is unreliable
  # when the capture UI is launched as a short-lived `flameshot gui` process.
  launchd.user.agents.flameshot = {
    serviceConfig = {
      ProgramArguments = [
        "${flameshot}/Applications/flameshot.app/Contents/MacOS/flameshot"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Interactive";
    };
  };

  # Use skhd instead of Apple Shortcuts so the public hotkey is managed by this
  # repo. It forwards Option+Shift+S to Flameshot's own global capture shortcut,
  # so the normal Flameshot GUI and clipboard owner stay in the primary app.
  services.skhd = {
    enable = true;
    skhdConfig = ''
      alt + shift - s : ${pkgs.skhd}/bin/skhd -k "cmd + shift - x"
    '';
  };
}
