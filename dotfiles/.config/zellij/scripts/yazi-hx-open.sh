#!/bin/bash
# ~/.config/zellij/scripts/yazi-hx-open.sh
#
# Smart opener: works in Zellij OR standalone (opens helix directly)
# $1 = file path to open

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Get absolute path
if command -v realpath &>/dev/null; then
  FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null) || true
fi

# Check if running inside Zellij
if [ -n "$ZELLIJ" ]; then
  # Running inside Zellij - send to helix pane
  ESCAPED_PATH=$(printf '%s' "$FILE_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')
  
  zellij action focus-next-pane
  sleep 0.05
  zellij action write 27
  zellij action write-chars ":open \"$ESCAPED_PATH\""
  zellij action write 13
else
  # Not in Zellij - just open helix directly with the file
  hx "$FILE_PATH"
fi

exit 0
