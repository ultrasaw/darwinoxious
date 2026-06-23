{ pkgs, config, lib, ... }:

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

    activation.opencodeThinkingMode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      kv_file="${config.xdg.stateHome}/opencode/kv.json"
      kv_dir="$(dirname "$kv_file")"

      if [ -n "$DRY_RUN_CMD" ]; then
        echo "Would set OpenCode thinking_mode in $kv_file"
      else
        mkdir -p "$kv_dir"
        tmp_file="$(mktemp "$kv_dir/kv.json.tmp.XXXXXX")"

        if [ -s "$kv_file" ] && ${pkgs.jq}/bin/jq empty "$kv_file" >/dev/null 2>&1; then
          ${pkgs.jq}/bin/jq '.thinking_mode = "show"' "$kv_file" > "$tmp_file"
        else
          ${pkgs.jq}/bin/jq -n '{ thinking_mode: "show" }' > "$tmp_file"
        fi

        mv "$tmp_file" "$kv_file"
      fi
    '';
  };
}
