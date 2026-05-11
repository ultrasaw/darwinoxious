{ config, pkgs, lib, unstablePkgs, ... }:

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

      timeout = "gtimeout";

      # Git Aliases
      ga = "git add";
      gc = "git commit";
      gg = "git pull";
      gp = "git push --set-upstream origin HEAD";
      gx = "git checkout";

      # cat
      bat = "bat --style=numbers --color=always -P";

      # Kubernetes
      k = "kubectl";
      kcurl = "k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5";

      # Other Aliases
      ld = "lazydocker";
      docker-clean = "docker container prune -f && docker image prune -f && docker network prune -f && docker volume prune -f";
      cr = "cargo run";
      y = "yazi";
      zc = "zellij --layout compact";
      zs = "zellij --layout split";
      oc = "opencode";
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

    initContent = ''
      # Pre-warm helix binary into RAM (reduces first-open delay)
      (cat $(which hx) > /dev/null 2>&1 &) 2>/dev/null

      # --- Start: Custom Terminal Title ---

      export DISABLE_AUTO_TITLE="true"

      set_term_title() {
        local my_emoji="🥱" # 🫥 👾 🥱
        print -Pn "\e]0;''${my_emoji}\a"
      }

      autoload -Uz add-zsh-hook
      add-zsh-hook precmd set_term_title

      # --- End: Custom Terminal Title ---

      # https://github.com/alacritty/alacritty/issues/1408#issuecomment-467970836
      bindkey "^[[1;3C" forward-word
      bindkey "^[[1;3D" backward-word
      
      bindkey "^[[1;9C" forward-word
      bindkey "^[[1;9D" backward-word

      # ripgrep + fzf
      ff() {
        if [ "$#" -eq 0 ]; then
          fzf --preview 'bat --style=numbers --color=always {}'
          return
        fi
        rg --files-with-matches --no-messages --hidden "$1" --glob "!.git/*" \
          | fzf --preview "bat --style=numbers --color=always {} | rg --passthru --color=always --colors 'match:bg:yellow' --colors 'match:fg:black' --ignore-case '$1'"
      }

      # ripgrep + fzf -> helix
      fh() {
        if [ "$#" -eq 0 ]; then
          rg --files --hidden --glob "!.git/*" \
            | fzf --preview 'bat --style=numbers --color=always {}' \
            | xargs -r hx
          return
        fi
        rg --files-with-matches --no-messages --hidden "$1" --glob "!.git/*" \
          | fzf --preview "bat --style=numbers --color=always {} | rg --passthru --color=always --colors 'match:bg:yellow' --colors 'match:fg:black' --ignore-case '$1'" \
          | xargs -r hx
      }

      # ripgrep + fzf -> replace in ALL filtered files (uses sd)
      # Usage: fr [-l] <search> <replace>
      #   -l  literal mode (no regex, exact string match)
      # Filter with fzf, press Enter to replace in ALL visible files
      fr() {
        local literal=""
        if [ "$1" = "-l" ]; then
          literal="-F"
          shift
        fi
        if [ "$#" -lt 2 ]; then echo "Usage: fr [-l] <search> <replace>"; return 1; fi
        local search="$1"
        local replace="$2"
        local rg_flag=""
        [ -n "$literal" ] && rg_flag="-F"
        local files
        files=$(rg --files-with-matches --no-messages --hidden $rg_flag "$search" --glob "!.git/*" | \
          fzf -m --preview "rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 $rg_flag '$search' {}" \
          --bind 'enter:select-all+accept')
        if [ -n "$files" ]; then
          echo "$files" | xargs sd $literal "$search" "$replace"
          echo "Replaced '$search' with '$replace' in:"
          echo "$files"
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
    settings.alias = {
      pu = "push";
      co = "checkout";
      cm = "commit";
    };
  };

  # a 'post-modern' text editor
  programs.helix = {
    enable = true;
    defaultEditor = true;
    package = unstablePkgs.helix;
  };

  # a modern tmux
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    package = unstablePkgs.zellij;
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

  # Kitty config moved to home/kitty.nix
  # Kitty app installed via modules/terminals.nix for proper /Applications linking

  # Define user environment packages
  home.packages = with pkgs; [
    # cmake
    # clang-tools

    htop
    # alacritty & kitty installed via modules/terminals.nix for proper /Applications linking
    neovim
    ueberzugpp # image previews for yazi in terminals without native graphics

    sd # sed alternative

    firebase-tools

    terraform-ls
    unstablePkgs.opentofu
    unstablePkgs.terragrunt

    unzip

    unstablePkgs.gh
    unstablePkgs.worktrunk
    unstablePkgs.gemini-cli
    unstablePkgs.opencode
    unstablePkgs.codex
    unstablePkgs.ollama

    unstablePkgs.kubectl
    unstablePkgs.k9s
    unstablePkgs.kubernetes-helm
    unstablePkgs.minikube
    unstablePkgs.kind
    unstablePkgs.fluxcd

    awscli2
    s3cmd
    unstablePkgs.rclone
    p4 # Perforce Helix Core command-line client and APIs

    (google-cloud-sdk.withExtraComponents [google-cloud-sdk.components.gke-gcloud-auth-plugin])

    sqlite
    jq
    yq-go
    openssl
    websocat
    hyperfine

    nerd-fonts.jetbrains-mono
  ];

  # fonts.fontconfig.enable = true;

}
