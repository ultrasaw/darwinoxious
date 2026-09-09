# Run without rebuilding the system:
# nix build --impure --no-link --file tests/gh-guard.nix
let
  flake = builtins.getFlake (toString ../.);
  pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
  unstablePkgs = import flake.inputs.nixpkgs-unstable {
    system = "aarch64-darwin";
    config.allowUnfree = true;
  };
  stub = pkgs.writeShellScriptBin "gh" ''
    if [[ "''${1:-}/''${2:-}" == repo/view ]]; then
      printf '<%s>\n' "$@" >> "$calls"
      printf '%s\n' "$STUB_RESOLVED"
      exit "''${STUB_RESOLVE_EXIT:-0}"
    fi
    printf 'called\n' >> "$forwarded"
    printf '<%s>\n' "$@"
    exit "''${STUB_EXIT:-0}"
  '';
  home = import ../home/common.nix {
    inherit pkgs;
    lib = pkgs.lib;
    config = { };
    unstablePkgs = unstablePkgs // { gh = stub; };
  };
  gh = pkgs.lib.findFirst (p: (p.name or "") == "gh-guarded") null home.home.packages;
in pkgs.runCommand "gh-guard-tests" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
  shellcheck ${gh}/bin/gh
  export calls="$TMPDIR/calls" forwarded="$TMPDIR/forwarded"
  export STUB_RESOLVED=other/project
  unset GH_REPO
  count=0

  deny() {
    : > "$forwarded"
    if output=$(${gh}/bin/gh "$@" 2>&1); then
      printf 'Unexpected success: %s\n' "$*" >&2
      exit 1
    fi
    [[ "$output" == *"$expected_error"* ]]
    test ! -s "$forwarded"
    count=$((count + 1))
  }

  allow() {
    output=$(${gh}/bin/gh "$@")
    [[ "$output" == "$(printf '<%s>\n' "$@")" ]]
    count=$((count + 1))
  }

  expected_error='release changes are blocked for Atlas-Design'
  for action in create new edit delete upload delete-asset; do
    deny release "$action" v-test -R Atlas-Design/atlas_gitops
  done
  for repo in Atlas-Design/atlas_gitops aTlAs-DeSiGn/unrelated-name github.com/Atlas-Design/atlas_gitops https://github.com/Atlas-Design/atlas_gitops; do
    deny release create v-test --repo "$repo"
    deny --repo="$repo" release create v-test
    deny release -R"$repo" create v-test
    deny release create v-test -R="$repo"
    deny release create v-test -dR"$repo"
  done
  export GH_REPO=Atlas-Design/atlas_gitops
  deny release create v-test
  deny release create v-test --repo=
  deny release create v-test --repo other/project --repo=
  allow release create v-test -R other/project
  deny release create v-test -R other/project -R Atlas-Design/atlas_gitops
  deny release create v-test --notes -Rother/project
  deny release create v-test -n -Rother/project
  deny release create v-test -dn -Rother/project
  deny release create v-test -- --repo other/project
  for value in false False FALSE f F 0; do
    deny release delete v-test --yes --help --help="$value"
  done
  deny release --yes v-test delete
  deny release --yes view delete
  deny --yes v-test release delete
  deny release -dn create --help v-test
  GH_REPO=other/project deny release -dR create Atlas-Design/atlas_gitops v-test
  allow release list --repo Atlas-Design/atlas_gitops
  for action in view download verify; do
    allow release "$action" v-test --repo Atlas-Design/atlas_gitops
  done
  allow release verify-asset v-test asset.tar.gz --repo Atlas-Design/atlas_gitops
  allow release create --help
  allow release create -h
  allow release create -dh --help=false
  allow release create --help=false --help=true
  allow api repos/Atlas-Design/atlas_gitops/releases -X POST
  allow pr list
  allow --version
  unset GH_REPO

  export STUB_RESOLVED=Atlas-Design/atlas_gitops
  deny release create v-test
  deny release create v-test -R old-owner/old-name
  export STUB_RESOLVED=other/project
  : > "$calls"
  allow release create v-test --notes 'notes with spaces' -t 'a title' -R other/project
  [[ "$(< "$calls")" == $'<repo>\n<view>\n<other/project>\n<--json>\n<nameWithOwner>\n<--jq>\n<.nameWithOwner>' ]]

  expected_error='repository could not be resolved'
  STUB_RESOLVE_EXIT=1 deny release create v-test
  STUB_RESOLVED= deny release create v-test
  status=0
  STUB_EXIT=42 ${gh}/bin/gh release list >/dev/null || status=$?
  test "$status" -eq 42
  printf '%s guard cases passed; exit status forwarding passed.\n' "$count"
  touch "$out"
''
