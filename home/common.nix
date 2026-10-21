{ config, pkgs, lib, unstablePkgs, ... }:

let
  ghGuard = pkgs.writeShellScriptBin "gh" ''
    args=("$@")
    command_name=""
    subcommand=""
    repo="''${GH_REPO:-}"
    help=false
    positional=false

    # Cobra discovers commands before parsing leaf flags. Unknown parent flags
    # consume a following word, even when the leaf later treats them as booleans.
    skip=false
    flag_args=("$@")
    for index in "''${!args[@]}"; do
      arg="''${args[index]}"
      if [[ "$skip" == true ]]; then skip=false; continue; fi
      case "$arg" in
        --) break ;;
        --help|--version|--*=*) continue ;;
        --*|-?) skip=true; continue ;;
        -*|"") continue ;;
      esac
      unset 'flag_args[index]'
      if [[ -z "$command_name" ]]; then
        command_name="$arg"
      else
        subcommand="$arg"
        break
      fi
    done

    # Cobra removes the command words before a cluster can consume flag values.
    set -- "''${flag_args[@]}"
    # Parse value-taking flags so notes/titles cannot be mistaken for repo flags.
    while (( $# )); do
      if [[ "$positional" == false ]]; then
        case "$1" in
          --) positional=true; shift; continue ;;
          --repo)
            repo="''${2:-}"
            shift
            if (( $# )); then shift; fi
            continue ;;
          --repo=*) repo="''${1#*=}"; shift; continue ;;
          --discussion-category|--notes|--notes-file|--notes-start-tag|--target|--title|--tag)
            shift
            if (( $# )); then shift; fi
            continue ;;
          --help|--help=true|--help=True|--help=TRUE|--help=t|--help=T|--help=1)
            help=true; shift; continue ;;
          --help=*) help=false; shift; continue ;;
          --*) shift; continue ;;
          -?*)
            flags="''${1#-}"
            shift
            # gh accepts shorthand clusters, e.g. -dRowner/repo and -ntitle.
            while [[ -n "$flags" ]]; do
              flag="''${flags:0:1}"
              flags="''${flags:1}"
              case "$flag" in
                h) exec ${unstablePkgs.gh}/bin/gh "''${args[@]}" ;;
                R|n|F|t)
                  if [[ -n "$flags" ]]; then
                    value="''${flags#=}"
                  else
                    value="''${1:-}"
                    if (( $# )); then shift; fi
                  fi
                  if [[ "$flag" == R ]]; then repo="$value"; fi
                  break ;;
                *)
                  # A boolean's explicit value consumes the rest of the cluster.
                  if [[ "$flags" == =* ]]; then break; fi ;;
              esac
            done
            continue ;;
        esac
      fi
      shift
    done
    repo="''${repo:-''${GH_REPO:-}}"

    case "$command_name/$subcommand" in
      release/create|release/new|release/edit|release/delete|release/upload|release/delete-asset)
        if [[ "$help" != true ]]; then
          # Block explicit protected targets offline, including URL/host forms.
          shopt -s nocasematch
          if [[ "$repo" == Atlas-Design/* || "$repo" == */Atlas-Design/* ]]; then
            printf 'gh: release changes are blocked for Atlas-Design repositories (%s).\n' "$repo" >&2
            exit 1
          fi

          target=()
          if [[ -n "$repo" ]]; then target=("$repo"); fi
          if ! resolved=$(${unstablePkgs.gh}/bin/gh repo view "''${target[@]}" --json nameWithOwner --jq .nameWithOwner) || [[ "$resolved" != */* ]]; then
            printf 'gh: refusing release change because the repository could not be resolved.\n' >&2
            exit 1
          fi
          if [[ "$resolved" == Atlas-Design/* ]]; then
            printf 'gh: release changes are blocked for Atlas-Design repositories (%s).\n' "$resolved" >&2
            exit 1
          fi
        fi ;;
    esac

    exec ${unstablePkgs.gh}/bin/gh "''${args[@]}"
  '';
  gh = pkgs.symlinkJoin {
    name = "gh-guarded";
    # Keep upstream man pages and completions, but expose only the guarded CLI.
    paths = [ ghGuard unstablePkgs.gh ];
    meta.mainProgram = "gh";
  };
  worktrunk = unstablePkgs.worktrunk.overrideAttrs (oldAttrs: {
    # These process-table tests cannot see processes inside the macOS Nix sandbox.
    checkFlags = (oldAttrs.checkFlags or [ ]) ++ [
      "--skip=shell::utils::tests::test_process_name_and_ppid_self"
      "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
    ];
  });
  chromeWrapper = name: pkgs.writeShellScriptBin name ''
    exec "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" "$@"
  '';
  ocw = pkgs.writeShellScriptBin "ocw" ''
    set -euo pipefail
    server="https://nixos.tail10b7c3.ts.net"

    # The foreground system service generates its own password on every start.
    # Fetch only this invocation's credential over authenticated SSH; never put
    # it in the Nix store, command arguments, shell history, or a local file.
    if ! password=$(/usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=10 tower 'python3 -' <<'PY'
    import re
    import subprocess
    import sys

    invocation = subprocess.check_output(
        ["systemctl", "show", "opencode-web.service", "--property=InvocationID", "--value"],
        text=True,
    ).strip()
    if not invocation:
        sys.exit("ocw: remote OpenCode service is not running")
    result = subprocess.run(
        ["journalctl", "_SYSTEMD_INVOCATION_ID=" + invocation,
         "--grep=^server password ", "-n", "1", "--no-pager", "-o", "cat", "--quiet"],
        capture_output=True, text=True, check=True,
    )
    match = re.search(r"^server password (.+)$", result.stdout, re.MULTILINE)
    if not match:
        sys.exit("ocw: cannot retrieve the active remote OpenCode credential")
    print(match.group(1))
    PY
    ); then
      echo "ocw: remote authentication lookup failed" >&2
      exit 1
    fi
    if [[ -z "$password" ]]; then
      echo "ocw: remote OpenCode returned an empty credential" >&2
      exit 1
    fi
    export OPENCODE_PASSWORD="$password"
    unset password

    if [[ "''${1:-}" == --check ]]; then
      exec ${unstablePkgs.opencode}/bin/opencode api --server "$server" get /api/info
    fi

    directory=""
    case "''${1:-}" in
      --dir|--directory)
        if (( $# < 2 )) || [[ -z "$2" ]]; then
          echo "Usage: ocw [--dir /remote/path] [opencode flags]" >&2
          exit 2
        fi
        directory="$2"
        shift 2 ;;
      --dir=*|--directory=*) directory="''${1#*=}"; shift ;;
      /*) directory="$1"; shift ;;
    esac
    if [[ -n "$directory" ]]; then
      if [[ "$directory" != /* ]]; then
        echo "ocw: use an absolute remote directory" >&2
        exit 2
      fi
      for arg in "$@"; do
        case "$arg" in
          --session|--session=*|-s|-s?*|--continue|-c)
            echo "ocw: --dir creates a session; omit it when resuming a session" >&2
            exit 2 ;;
        esac
      done
      body=$(${pkgs.jq}/bin/jq -cn --arg directory "$directory" '{location: {directory: $directory}}')
      session=$(${unstablePkgs.opencode}/bin/opencode api --server "$server" post /api/session --data "$body" \
        | ${pkgs.jq}/bin/jq -er '.data.id')
      exec ${unstablePkgs.opencode}/bin/opencode --server "$server" --session "$session" "$@"
    fi
    exec ${unstablePkgs.opencode}/bin/opencode --server "$server" "$@"
  '';
in {

  home.stateVersion = "24.11";

  programs = {
    home-manager.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      # OrbStack requires this global include to precede all Host blocks.
      includes = [ "~/.orbstack/ssh/config" ];
      settings = {
        "github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/gh_key";
        };
        tower = {
          HostName = "nixos";
          User = "gio";
          IdentityFile = "~/.ssh/nixos_tower";
          IdentitiesOnly = true;
          ProxyCommand = "${unstablePkgs.tailscale}/bin/tailscale nc %h %p";
        };
      };
    };
    yazi = {
      enable = true; # terminal file manager
      shellWrapperName = "yy";
    };
    btop.enable = true; # TUI for resource usage monitoring
    bat.enable = true; # cat with syntax highlighting
  };

  # The existing OrbStack and GitHub entries are declared above.
  home.file.".ssh/config".force = true;

  home.activation.createNixosTowerKeyPlaceholder = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ssh_dir="$HOME/.ssh"
    private_key="$ssh_dir/nixos_tower"

    if [[ ! -d "$ssh_dir" ]]; then
      run install -d -m 0700 "$ssh_dir"
    fi

    if [[ ! -e "$private_key" ]]; then
      run install -m 0600 /dev/null "$private_key"
    fi
  '';

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
      ocw = "${ocw}/bin/ocw";
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

      # kubeconfig from existing .yaml files. Newest files are first, so the
      # last refreshed cluster becomes the default without hard-coding names.
      kubeconfig_files=(
        "$HOME"/.kube/*.yaml(Nom)
      )
      typeset -U kubeconfig_files

      if (( ''${#kubeconfig_files} )); then
        export KUBECONFIG="''${(j/:/)kubeconfig_files}"
      else
        unset KUBECONFIG
      fi
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

    gh
    worktrunk
    unstablePkgs.opencode
    ocw
    unstablePkgs.codex
    unstablePkgs.ollama

    (chromeWrapper "google-chrome")
    (chromeWrapper "google-chrome-stable")

    unstablePkgs.kubectl
    unstablePkgs.k9s
    unstablePkgs.kubernetes-helm
    unstablePkgs.kind
    unstablePkgs.fluxcd
    unstablePkgs.sops
    unstablePkgs.hcloud

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
