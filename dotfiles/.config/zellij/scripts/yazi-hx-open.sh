#!/bin/bash
# ~/.config/zellij/scripts/yazi-hx-open.sh
#
# Called by yazi opener - opens file in Helix and switches focus
# $1 = file path to open

FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Get absolute path
if command -v realpath &>/dev/null; then
  FILE_PATH=$(realpath "$FILE_PATH" 2>/dev/null) || true
fi

ESCAPED_PATH=$(printf '%s' "$FILE_PATH" | sed 's/\\/\\\\/g; s/"/\\"/g')

# Focus Helix pane
zellij action focus-next-pane

# Escape for normal mode
zellij action write 27

# Open file
zellij action write-chars ":open \"$ESCAPED_PATH\""
zellij action write 13

# Stay in Helix pane

exit 0
