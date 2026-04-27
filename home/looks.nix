{ pkgs, config, ... }:

let
  homeDir = config.home.homeDirectory;
  projectsDir = "${homeDir}/Documents/_projects";
in
{
  home = {
    file = {
      # # Top Level Files symlinks
      # ".zshrc".source = ../../dotfiles/.zshrc;
      # ".zshenv".source = ../../dotfiles/.zshenv;
      
      # # Config directories
      ".config/alacritty".source = ../dotfiles/.config/alacritty;
      ".config/helix".source = ../dotfiles/.config/helix;
      ".config/starship.toml".source = ../dotfiles/.config/starship/starship.toml;
      # ".config/rstudio/themes".source = ../dotfiles/.config/rstudio/themes;
      ".config/zellij".source = ../dotfiles/.config/zellij;
      ".config/yazi".source = ../dotfiles/.config/yazi;
      ".config/yazi-minimal".source = ../dotfiles/.config/yazi-minimal;

      # Executable scripts need explicit permissions
      ".config/zellij/scripts/fzf-hx-open.sh" = {
        text       = builtins.readFile ../dotfiles/.config/zellij/scripts/fzf-hx-open.sh;
        executable = true;
      };
      ".config/zellij/scripts/yazi-hx-open.sh" = {
        text       = builtins.readFile ../dotfiles/.config/zellij/scripts/yazi-hx-open.sh;
        executable = true;
      };
      ".config/zellij/scripts/toggle-preview.sh" = {
        text       = builtins.readFile ../dotfiles/.config/zellij/scripts/toggle-preview.sh;
        executable = true;
      };

      # Manual install on non-nix machines:
      #   sed -e "s|@PROJECTS_DIR@|$HOME/Documents/_projects|g" \
      #       -e "s|@HOME@|$HOME|g" \
      #       dotfiles/.config/opencode/opencode.json \
      #       > ~/.config/opencode/opencode.json
      ".config/opencode/opencode.json".text = builtins.replaceStrings
        [ "@PROJECTS_DIR@" "@HOME@" ]
        [ projectsDir   homeDir ]
        (builtins.readFile ../dotfiles/.config/opencode/opencode.json);
    };
  };
}
