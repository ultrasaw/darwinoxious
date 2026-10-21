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

    # V2 owns a writable cli.json. Merge our preferences without replacing
    # unrelated settings saved by the TUI or symlinking it into the Nix store.
    activation.opencodeCliSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      cli_file="${config.xdg.configHome}/opencode/cli.json"
      cli_dir="$(dirname "$cli_file")"

      if [ -n "$DRY_RUN_CMD" ]; then
        echo "Would merge OpenCode CLI settings into $cli_file"
      else
        mkdir -p "$cli_dir"
        tmp_file="$(mktemp "$cli_dir/cli.json.tmp.XXXXXX")"

        if [ -e "$cli_file" ]; then
          if ! ${pkgs.jq}/bin/jq -e -s \
            'if (.[0] | type) == "object" then .[0] * .[1] else error("cli.json must be an object") end' \
            "$cli_file" ${../dotfiles/.config/opencode/cli.json} > "$tmp_file"; then
            rm -f "$tmp_file"
            echo "Refusing to overwrite invalid OpenCode CLI settings: $cli_file" >&2
            exit 1
          fi
          if [ ! -e "$cli_file.before-nix-v2" ]; then
            cp -p "$cli_file" "$cli_file.before-nix-v2"
          fi
        else
          ${pkgs.jq}/bin/jq . ${../dotfiles/.config/opencode/cli.json} > "$tmp_file"
        fi

        chmod 0600 "$tmp_file"
        mv "$tmp_file" "$cli_file"
      fi
    '';
  };
}
