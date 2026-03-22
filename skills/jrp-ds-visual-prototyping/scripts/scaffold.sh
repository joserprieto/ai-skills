#!/usr/bin/env bash
# =============================================================================
# scaffold.sh — Create a mini-app pre-loaded with the joserprieto Design System
#
# Usage:
#   bash scaffold.sh --type react|astro [--output /path] [--config /path/to/config.yaml]
#
# The script:
#   1. Reads config.default.yaml (merges config.local.yaml if present)
#   2. Copies the chosen template to the output directory
#   3. Symlinks DS assets (tokens.css, main.css, sprite, fonts)
#   4. Installs dependencies with pnpm
#   5. Starts dev server in background
#   6. Prints the URL
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# =============================================================================
# Argument parsing
# =============================================================================

TYPE=""
OUTPUT=""
CONFIG_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      TYPE="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --config)
      CONFIG_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$TYPE" ]]; then
  echo "Error: --type is required (react or astro)" >&2
  exit 1
fi

if [[ "$TYPE" != "react" && "$TYPE" != "astro" ]]; then
  echo "Error: --type must be 'react' or 'astro'" >&2
  exit 1
fi

# =============================================================================
# Config resolution (simple YAML parsing — no external deps)
# =============================================================================

parse_yaml_value() {
  local file="$1"
  local key="$2"
  # Extract value for a key like "  tokens: value" — handles inline comments
  grep -E "^\s+${key}:" "$file" 2>/dev/null | head -1 | sed 's/^[^:]*:\s*//' | sed 's/\s*#.*//' | xargs
}

parse_yaml_root_value() {
  local file="$1"
  local key="$2"
  grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed 's/^[^:]*:\s*//' | sed 's/\s*#.*//' | xargs
}

DEFAULT_CONFIG="$SKILL_DIR/config.default.yaml"
LOCAL_CONFIG="$SKILL_DIR/config.local.yaml"

if [[ -n "$CONFIG_FILE" ]]; then
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
  fi
  DEFAULT_CONFIG="$CONFIG_FILE"
  LOCAL_CONFIG=""  # Custom config = no local merge
fi

# Read from default, override with local if present
read_config() {
  local key="$1"
  local value=""
  if [[ -n "$LOCAL_CONFIG" && -f "$LOCAL_CONFIG" ]]; then
    value=$(parse_yaml_value "$LOCAL_CONFIG" "$key")
  fi
  if [[ -z "$value" ]]; then
    value=$(parse_yaml_value "$DEFAULT_CONFIG" "$key")
  fi
  # Expand ~ to HOME
  echo "${value/#\~/$HOME}"
}

read_root_config() {
  local key="$1"
  local value=""
  if [[ -n "$LOCAL_CONFIG" && -f "$LOCAL_CONFIG" ]]; then
    value=$(parse_yaml_root_value "$LOCAL_CONFIG" "$key")
  fi
  if [[ -z "$value" ]]; then
    value=$(parse_yaml_root_value "$DEFAULT_CONFIG" "$key")
  fi
  echo "${value/#\~/$HOME}"
}

DS_ROOT=$(read_config "root")
DS_TOKENS=$(read_config "tokens")
DS_STYLES=$(read_config "styles")
DS_SPRITE=$(read_config "sprite")
DS_FONTS=$(read_config "fonts")
DS_COMPONENTS=$(read_config "components")
CONFIG_OUTPUT=$(read_root_config "output")

# =============================================================================
# Resolve paths
# =============================================================================

TOKENS_PATH="$DS_ROOT/$DS_TOKENS"
STYLES_PATH="$DS_ROOT/$DS_STYLES"
FONTS_PATH="$DS_ROOT/$DS_FONTS"
COMPONENTS_PATH="$DS_ROOT/$DS_COMPONENTS"

# Sprite uses glob pattern (pnpm nested node_modules)
resolve_glob() {
  local pattern="$1"
  local matches
  # Word splitting is intentional — expanding a glob pattern into an array
  # shellcheck disable=SC2206
  matches=($pattern)
  if [[ ${#matches[@]} -gt 0 && -f "${matches[0]}" ]]; then
    echo "${matches[0]}"
  fi
}

SPRITE_PATH=$(resolve_glob "$DS_ROOT/$DS_SPRITE")

# =============================================================================
# Validate paths
# =============================================================================

echo "=== jrp-ds-visual-prototyping ==="
echo ""
echo "Framework: $TYPE"
echo "DS root:   $DS_ROOT"
echo ""

errors=0

check_path() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    echo "  [OK] $label: $path"
  else
    echo "  [MISSING] $label: $path"
    errors=$((errors + 1))
  fi
}

check_path "Tokens" "$TOKENS_PATH"
check_path "Styles" "$STYLES_PATH"

if [[ -n "$SPRITE_PATH" ]]; then
  echo "  [OK] Sprite: $SPRITE_PATH"
else
  echo "  [MISSING] Sprite: $DS_ROOT/$DS_SPRITE (glob matched nothing)"
  errors=$((errors + 1))
fi

check_path "Fonts" "$FONTS_PATH"

if [[ "$TYPE" == "astro" ]]; then
  check_path "Components" "$COMPONENTS_PATH"
fi

echo ""

if [[ $errors -gt 0 ]]; then
  echo "Error: $errors DS path(s) missing. Build the DS first: cd $DS_ROOT && pnpm build" >&2
  echo "Or create config.local.yaml with correct paths." >&2
  exit 1
fi

# =============================================================================
# Determine output directory
# =============================================================================

if [[ -n "$OUTPUT" ]]; then
  OUTPUT_DIR="$OUTPUT"
else
  TIMESTAMP=$(date +%s)
  OUTPUT_DIR="${CONFIG_OUTPUT//\{timestamp\}/$TIMESTAMP}"
fi

echo "Output: $OUTPUT_DIR"
echo ""

# =============================================================================
# Copy template
# =============================================================================

TEMPLATE_DIR="$SKILL_DIR/templates/$TYPE"

if [[ ! -d "$TEMPLATE_DIR" ]]; then
  echo "Error: Template not found: $TEMPLATE_DIR" >&2
  exit 1
fi

echo "Copying $TYPE template..."
cp -r "$TEMPLATE_DIR" "$OUTPUT_DIR"

# =============================================================================
# Create symlinks to DS assets
# =============================================================================

echo "Creating symlinks to DS assets..."

ASSETS_DIR="$OUTPUT_DIR/public/ds"
mkdir -p "$ASSETS_DIR"

ln -sf "$TOKENS_PATH" "$ASSETS_DIR/tokens.css"
ln -sf "$STYLES_PATH" "$ASSETS_DIR/main.css"

if [[ -n "$SPRITE_PATH" ]]; then
  ln -sf "$SPRITE_PATH" "$ASSETS_DIR/tabler-sprite.svg"
fi

# Symlink each font directory (inter, jetbrains-mono, titillium-web)
FONTS_LINK_DIR="$ASSETS_DIR/fonts"
mkdir -p "$FONTS_LINK_DIR"
for font_dir in "$FONTS_PATH"/*/; do
  if [[ -d "$font_dir" ]]; then
    font_name=$(basename "$font_dir")
    ln -sf "$font_dir" "$FONTS_LINK_DIR/$font_name"
  fi
done

echo "  Symlinked: tokens.css, main.css, tabler-sprite.svg, fonts/"

# =============================================================================
# Install dependencies
# =============================================================================

echo ""
echo "Installing dependencies..."
cd "$OUTPUT_DIR"
pnpm install --prefer-offline 2>&1 | tail -3

# =============================================================================
# Pick a random port
# =============================================================================

if [[ "$TYPE" == "react" ]]; then
  PORT=$((RANDOM % 100 + 4900))
else
  PORT=$((RANDOM % 100 + 5900))
fi

# =============================================================================
# Start dev server
# =============================================================================

echo ""
echo "Starting $TYPE dev server on port $PORT..."

if [[ "$TYPE" == "react" ]]; then
  npx vite --port "$PORT" &
else
  npx astro dev --port "$PORT" &
fi

DEV_PID=$!
echo "Dev server PID: $DEV_PID"
echo ""
echo "========================================="
echo "  Proto ready: http://localhost:$PORT"
echo "  Output dir:  $OUTPUT_DIR"
echo "  Stop:        kill $DEV_PID"
echo "========================================="
