{ config, pkgs, lib, ... }:

{

  home.stateVersion = "24.11";

  programs = {
    home-manager.enable = true;
    yazi.enable = true; # terminal file manager
    btop.enable = true; # TUI for resource usage monitoring
    bat.enable = true; # cat with syntax highlighting
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      vim = "nvim";

      # Git Aliases
      ga = "git add";
      gc = "git commit";
      gp = "git push";

      # cat
      cat = "bat --style=numbers --color=always -P"

      # Kubernetes
      k = "kubectl";
      kcurl = "k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5";

      # Other Aliases
      ld = "lazydocker";
      docker-clean = "docker container prune -f && docker image prune -f && docker network prune -f && docker volume prune -f";
      cr = "cargo run";
      y = "yazi";
      zc = "zellij --layout compact";
      zs = "zellij --layout split"
    };

    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/zsh_history";
    };

    oh-my-zsh = {
      enable = false;
      plugins = [ ];
      theme = "clean"; # agnoster, amuse, arrow, clean
    };

    initExtra = ''
      # https://github.com/alacritty/alacritty/issues/1408#issuecomment-467970836
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word

      # ripgrep + fzf
      fif() {
        if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
        rg --files-with-matches --no-messages --hidden "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
      }

      fh() {
          # Check if a search string is provided
          if [ ! "$#" -gt 0 ]; then
              echo "Usage: fh <search_string>"
              echo "Need a string to search for!"
              return 1
          fi

          local search_string="$1"

          # Build the rg command to find files with matches
          # Use --color=never to ensure clean filenames for fzf
          local rg_command="rg --files-with-matches --no-messages --hidden --color=never \"$search_string\""

          # Build the fzf preview command (same as yours)
          # Highlight the file, then use rg to show matches with context and highlighting
          # Need to be careful with quotes here, especially around the search_string for the inner rg
          local preview_command='highlight -O ansi -l {} 2> /dev/null | rg --colors "match:bg:yellow" --ignore-case --pretty --context 10 "'"$search_string"'" || rg --ignore-case --pretty --context 10 "'"$search_string"'" {}'


          # Run rg, pipe to fzf with preview, and capture the selected file
          # Using eval allows rg_command to handle potentially complex search strings with quotes
          local selected_file
          selected_file=$(eval "$rg_command" | fzf --preview "$preview_command")

          # Check if a file was selected (fzf returns empty string if cancelled)
          if [ -z "$selected_file" ]; then
              echo "No file selected or selection cancelled."
              return 0
          fi

          # Check if we are inside a Zellij environment by checking if $ZELLIJ is non-empty
          # Based on your testing, it's '0' inside Zellij and empty outside.
          if [ -n "$ZELLIJ" ]; then # Check if $ZELLIJ variable is set and is not an empty string
              echo "Zellij environment detected. Splitting pane and opening $selected_file in hx."
              # Use zellij action new-pane to create a new pane and run a command in it.
              # The -- separates Zellij's options from the command to be run in the new pane.
              # We use sh -c 'exec hx "$@"' -- "$selected_file" to robustly pass the filename
              # to hx in the new shell.
              zellij action new-pane --direction Right -- sh -c 'exec hx "$@"' -- "$selected_file"

              # Zellij usually focuses the new pane by default, which is what we want here.
              # If you needed to explicitly focus it later, you could use:
              # zellij action focus-pane --direction Right # Focus the pane to the right of the current

          else
              # Not in Zellij (or $ZELLIJ isn't set), open in the current window
              echo "Not in a Zellij environment. Opening $selected_file in hx in the current window."
              hx "$selected_file"
              # Note: When not in Zellij (or Tmux/Wezterm etc.), opening helix will
              # replace the current process (fzf). To get the split-pane behavior
              # and keep fzf visible, you MUST use a terminal multiplexer like Zellij.
          fi
      }

      # Environment variables
      export do="--dry-run=client -o yaml"
      export now="--force --grace-period 0"

      # Source kubectl completion script
      source <(kubectl completion zsh)

      # kubeconfig from multiple .yaml files
      export KUBECONFIG="$HOME/.kube/cl-k8s-gitlab-runner-dev-01.yaml:$HOME/.kube/cl-k8s-workload-prod-01.yaml:$HOME/.kube/devcluster01-test.yaml:$HOME/.kube/devcluster01.yaml:$HOME/.kube/devcluster02.yaml:$HOME/.kube/internalservice-ng.yaml:$HOME/.kube/local.yaml:$HOME/.kube/prodcluster01-rke2.yaml:$HOME/.kube/workloaddev01-test.yaml:$HOME/.kube/workloaddev01.yaml"
    '';
  };

  # ls replacement
  programs.eza.enable = true;
  programs.eza.enableZshIntegration = true;

  programs.git = {
    enable = true;
    aliases = {
      pu = "push";
      co = "checkout";
      cm = "commit";
    };
  };

  # a 'post-modern' text editor
  programs.helix = {
    enable = true;
    defaultEditor = true;
  };

  # a modern tmux
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
  };

  # a better 'cd'
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # a fuzzy finder
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # a recursive search tool
  programs.ripgrep = {
    enable = true;
  };

  # Define user environment packages
  home.packages = with pkgs; [
    htop
    # alacritty
    neovim

    terraform

    unzip

    kubectl
    k9s

    awscli2
    s3cmd
    aws-sam-cli

    openssl

    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];

  # fonts.fontconfig.enable = true;

}
