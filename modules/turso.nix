# Turso CLI - not in nixpkgs, built from source with buildGoModule.
# https://github.com/tursodatabase/turso-cli
#
# To update:
#   1. Bump `version` to the new tag (check releases page).
#   2. Set `hash` to a fake value (e.g. lib.fakeHash), rebuild, and copy
#      the correct hash from the error message.
#   3. Do the same for `vendorHash` (it changes when Go dependencies change).
{ unstablePkgs, ... }:

let
  turso-cli = unstablePkgs.buildGoModule rec {
    pname = "turso-cli";
    version = "1.0.24";

    src = unstablePkgs.fetchFromGitHub {
      owner = "tursodatabase";
      repo = "turso-cli";
      rev = "v${version}";
      hash = "sha256-3fKEFK4zCeKEYfiBJ7so5pZ3ZQC2td80XKWN3GKFWLA=";
    };

    vendorHash = "sha256-Cb4/KA9jfI/pNHbJqLWtm9oEXfMHGBS46J9o3lL4/Tk=";

    subPackages = [ "cmd/turso" ];
  };
in
{
  environment.systemPackages = [ turso-cli ];
}
