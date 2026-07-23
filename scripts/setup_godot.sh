#!/usr/bin/env bash
# Idempotent Godot 4.4 headless binary setup.
# If `godot` is already on PATH, or already set up under ./godot, does nothing.
# Otherwise downloads the official godotengine/godot 4.4-stable Linux release,
# unzips it to .godot-bin/, and symlinks it as ./godot.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GODOT_VERSION="4.4-stable"
GODOT_ZIP="Godot_v${GODOT_VERSION}_linux.x86_64.zip"
GODOT_BIN_NAME="Godot_v${GODOT_VERSION}_linux.x86_64"
GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_ZIP}"

BIN_DIR="$PROJECT_DIR/.godot-bin"
SYMLINK="$PROJECT_DIR/godot"

if command -v godot >/dev/null 2>&1; then
	echo "godot already on PATH: $(command -v godot)"
	exit 0
fi

if [ -x "$SYMLINK" ]; then
	echo "godot already set up at $SYMLINK"
	exit 0
fi

mkdir -p "$BIN_DIR"
echo "Downloading Godot ${GODOT_VERSION} from ${GODOT_URL}..."
curl -sSL -o "$BIN_DIR/$GODOT_ZIP" "$GODOT_URL"

echo "Unzipping..."
unzip -o -q "$BIN_DIR/$GODOT_ZIP" -d "$BIN_DIR"

BIN_PATH="$BIN_DIR/$GODOT_BIN_NAME"
if [ ! -f "$BIN_PATH" ]; then
	# Release zip layout has occasionally changed; fall back to a search.
	BIN_PATH="$(find "$BIN_DIR" -maxdepth 1 -type f -name 'Godot_v*_linux.x86_64' | head -n1)"
fi

if [ -z "$BIN_PATH" ] || [ ! -f "$BIN_PATH" ]; then
	echo "Could not locate the extracted Godot binary under $BIN_DIR" >&2
	exit 1
fi

chmod +x "$BIN_PATH"
ln -sf "$BIN_PATH" "$SYMLINK"

echo "Godot set up at $SYMLINK"
"$SYMLINK" --version
