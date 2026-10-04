#!/usr/bin/env bash
set -euo pipefail

GODOT_VERSION="${GODOT_VERSION:-4.7.2}"
RELEASE_TAG="${GODOT_VERSION}-stable"
TEMP_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/godot-${GODOT_VERSION}"
TEMPLATE_DIR="$HOME/.local/share/godot/export_templates/${GODOT_VERSION}.stable"

mkdir -p "$TEMP_DIR" "$TEMPLATE_DIR"

curl --fail --location --retry 3 --silent --show-error \
  "https://github.com/godotengine/godot/releases/download/${RELEASE_TAG}/Godot_v${RELEASE_TAG}_linux.x86_64.zip" \
  --output "$TEMP_DIR/godot.zip"
unzip -q -o "$TEMP_DIR/godot.zip" -d "$TEMP_DIR"
sudo install -m 0755 "$TEMP_DIR/Godot_v${RELEASE_TAG}_linux.x86_64" /usr/local/bin/godot

if [[ ! -f "$TEMPLATE_DIR/web_release.zip" || ! -f "$TEMPLATE_DIR/android_debug.apk" ]]; then
  curl --fail --location --retry 3 --silent --show-error \
    "https://github.com/godotengine/godot/releases/download/${RELEASE_TAG}/Godot_v${RELEASE_TAG}_export_templates.tpz" \
    --output "$TEMP_DIR/export_templates.tpz"
  mkdir -p "$TEMP_DIR/templates"
  unzip -q -o "$TEMP_DIR/export_templates.tpz" -d "$TEMP_DIR/templates"
  cp -a "$TEMP_DIR/templates/templates/." "$TEMPLATE_DIR/"
fi

godot --version
