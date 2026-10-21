_:

[
  "glow" # render .md on the CLI
  "argo" # argo workflows
  "circleci"
  "tree"
  "coreutils" # for 'timeout'
  # Work around Bundle trying to clean up these coreutils runtime dependencies
  # during upgrades. Keep them explicit even if its dependency cache is stale.
  "openssl@4"
  "ca-certificates"
  "xcodes" # download/install full Xcode from Apple Developer
]
