## Nix-darwin w/ Homebrew casks + home-manager

Install Nix
```bash
curl -sSf -L https://install.lix.systems/lix | sh -s -- install # Determinite NO
```

Initizliaze Flakes
```bash
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

# To use Nixpkgs 24.11:
nix flake init -t nix-darwin/nix-darwin-24.11

sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
```

Build the system
```bash
nix run nix-darwin/nix-darwin-24.11#darwin-rebuild -- switch # on 1st build

darwin-rebuild switch # all consecutive builds

softwareupdate --install-rosetta
```
