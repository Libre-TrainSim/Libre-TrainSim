#!/usr/bin/env bash
# Local check: import resources, then parse all GDScript files (matches CI).
# Requires Godot 4.4 editor binary (same major.minor as project features).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="${ROOT}/src"

if [[ -z "${GODOT_BIN:-}" ]]; then
	echo "Set GODOT_BIN to your Godot 4.x editor binary, e.g.:" >&2
	echo '  export GODOT_BIN="$HOME/Apps/Godot_v4.4-stable_linux.x86_64"' >&2
	exit 1
fi

"$GODOT_BIN" --headless --path "$PROJECT_DIR" --import
exec "$GODOT_BIN" --headless --path "$PROJECT_DIR" -s res://tools/ci_validate_scripts.gd "$@"
