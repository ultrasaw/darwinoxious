## Nix-darwin w/ Homebrew casks + home-manager

### base
Install Nix
```bash
# Determinite NO
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

Initizliaze Flakes
```bash
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin

# To get started using Nix, open a new shell or run
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# To use Nixpkgs 25.05:
nix flake init -t nix-darwin/nix-darwin-25.05

sed -i '' "s/simple/$(scutil --get LocalHostName)/" flake.nix
```

Build the system
```bash
# on 1st build
nix run nix-darwin/nix-darwin-25.05#darwin-rebuild -- switch

# all consecutive builds
darwin-rebuild switch

softwareupdate --install-rosetta
```

Allow 'malware'
```bash
# https://github.com/alacritty/alacritty/issues/6500
xattr -dr com.apple.quarantine "/Applications/Alacritty.app"
```

### set up SSH / GPG keys
SSH
```bash
# save under '~/.ssh/gh_key'
ssh-keygen -t ed25519 -C "email@example.com"

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/gh_key

# print the public key, copy it and add it to e.g. Github
cat ~/.ssh/gh_key

# open the SSH config
vi ~/.ssh/config

# add the key to the SSH config
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/gh_key
```

GPG
```bash
gpg --full-generate-key

# get the key in the 'sec' line
gpg --list-secret-keys --keyid-format=long

# copy the public key block and add it to e.g. Github
gpg --armor --export KEY_ID

# enable signed commits
sudo git config --global user.name "Your Name"
sudo git config --global user.email "email@example.com"
sudo git config --global user.signingkey KEY_ID
sudo git config --global commit.gpgsign true
```
