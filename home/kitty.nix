# home/kitty.nix
# Kitty terminal configuration (home-manager)
# The app itself is installed via modules/terminals.nix for proper /Applications linking
{ ... }:

{
  programs.kitty = {
    enable = true;
    shellIntegration.enableZshIntegration = false;
    themeFile = "Adwaita_dark";

    font = {
      # Nerd Fonts installed via nix use "Mono" suffix for monospace variant
      name = "JetBrainsMono Nerd Font Mono";
      size = 15;
    };

    # See: https://sw.kovidgoyal.net/kitty/conf/
    settings = {
      # --- Window Size ---
      remember_window_size = false;
      initial_window_width = "140c";  # 140 columns (wider)
      initial_window_height = "42c";  # 42 rows (slightly taller)

      # --- Appearance ---
      background_opacity = "1.0";
      window_padding_width = 10;
      cursor_shape = "Block";
      cursor_blink_interval = 0;

      # --- Behavior ---
      scrollback_lines = 10000;
      copy_on_select = true;
      strip_trailing_spaces = "smart";
      enable_audio_bell = false;
      confirm_os_window_close = 0;
      macos_option_as_alt = "both";

      # --- Tab Bar ---
      shell_integration = "no-title"; # Let zsh set_term_title() control the title

      # --- URL Handling ---
      open_url_with = "default";

      # --- Performance ---
      sync_to_monitor = true;
    };

    # See: https://sw.kovidgoyal.net/kitty/actions/
    keybindings = {
      "alt+t" = "new_tab_with_cwd";
      "alt+shift+]" = "next_tab";
      "alt+shift+[" = "previous_tab";
    };
  };
}
