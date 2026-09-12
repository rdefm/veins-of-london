#!/usr/bin/env bash
# Idempotent install of the Godot AI editor plugin (github.com/hi-godot/godot-ai)
# into addons/godot_ai/. Does nothing if that directory already exists.
#
# Downloads the signed v4 release triple (plugin zip + manifest + manifest
# signature) straight from the GitHub release -- no `gh` CLI required, just
# curl -- and verifies it with the project's own release_verify module
# (installed on demand via `uvx --from godot-ai==<pin>`) before extracting.
# That module checks the manifest's RSA signature against the key compiled
# into the godot-ai package itself, checks the archive's sha256 against the
# signed manifest, and only then unpacks it. Never skip verification and
# unzip a downloaded release by hand -- this plugin runs inside the Godot
# editor with tool-execution access to the project.
#
# addons/godot_ai/ is gitignored (it self-updates via its own dock and isn't
# part of the shipped game) so every machine needs this once.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

GODOT_AI_VERSION="4.1.0"
GODOT_AI_TAG="v${GODOT_AI_VERSION}"
GODOT_AI_CHANNEL="stable"
REPO="hi-godot/godot-ai"
DEST="$PROJECT_DIR/addons/godot_ai"

if [ -e "$DEST" ]; then
	echo "godot-ai already installed at $DEST"
	exit 0
fi

if ! command -v uvx >/dev/null 2>&1; then
	echo "uvx not found. Install uv (https://docs.astral.sh/uv/getting-started/installation/) first." >&2
	exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

BASE_URL="https://github.com/${REPO}/releases/download/${GODOT_AI_TAG}"
echo "Downloading godot-ai ${GODOT_AI_TAG} release assets..."
curl -sSL -o "$WORK_DIR/godot-ai-v4-plugin.zip" "${BASE_URL}/godot-ai-v4-plugin.zip"
curl -sSL -o "$WORK_DIR/godot-ai-v4-plugin.manifest.json" "${BASE_URL}/godot-ai-v4-plugin.manifest.json"
curl -sSL -o "$WORK_DIR/godot-ai-v4-plugin.manifest.sig" "${BASE_URL}/godot-ai-v4-plugin.manifest.sig"

# The tag's exact commit, resolved independently of the (mutable) release
# notes, so it can be pinned below as part of `expected` rather than trusted
# from the manifest it's meant to check.
SOURCE_COMMIT="$(
	curl -sSL "https://api.github.com/repos/${REPO}/git/refs/tags/${GODOT_AI_TAG}" \
		| python -c "import json,sys; print(json.load(sys.stdin)['object']['sha'])"
)"

echo "Verifying signature and staging (uvx --from godot-ai==${GODOT_AI_VERSION})..."
STAGE_DIR="$WORK_DIR/staged"
# The uvx-launched python is a native Windows build under Git Bash, which
# can't resolve MSYS-style /tmp/... paths -- translate for it there.
if command -v cygpath >/dev/null 2>&1; then
	PY_WORK_DIR="$(cygpath -w "$WORK_DIR")"
	PY_STAGE_DIR="$(cygpath -w "$STAGE_DIR")"
else
	PY_WORK_DIR="$WORK_DIR"
	PY_STAGE_DIR="$STAGE_DIR"
fi
uvx --from "godot-ai==${GODOT_AI_VERSION}" python -c "
from pathlib import Path
from godot_ai import release_verify as rv

work = Path(r'''$PY_WORK_DIR''')
expected = ('$REPO', '$GODOT_AI_CHANNEL', '$GODOT_AI_TAG', '$GODOT_AI_VERSION', '$SOURCE_COMMIT')
plugin_dir, _digest, manifest = rv.stage_verified_release(
	work / 'godot-ai-v4-plugin.zip',
	work / 'godot-ai-v4-plugin.manifest.json',
	work / 'godot-ai-v4-plugin.manifest.sig',
	expected,
	Path(r'''$PY_STAGE_DIR'''),
)
print('verified', manifest['version'], 'commit', manifest['source_commit'])
"

mkdir -p "$PROJECT_DIR/addons"
mv "$STAGE_DIR/addons/godot_ai" "$DEST"
echo "godot-ai installed at $DEST"
echo "Enable it in Godot: Project > Project Settings > Plugins > Godot AI (already listed in project.godot's [editor_plugins])."
