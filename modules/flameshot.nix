{ ... }:

{
  # Use skhd instead of Apple Shortcuts so the Flameshot hotkey is managed by
  # this repo. macOS still requires granting Accessibility to skhd and Screen
  # Recording to Flameshot the first time this is activated.
  services.skhd = {
    enable = true;
    skhdConfig = ''
      alt + shift - s : open -na /Applications/flameshot.app --args gui
    '';
  };
}
