#!/usr/bin/env bash
# Generate wildest.nvim screenshots using Charmbracelet VHS
#
# Usage:
#   ./generate.sh                  # Generate all screenshots
#   ./generate.sh theme_saloon     # Generate a single screenshot
#   ./generate.sh --list           # List available configs
#   ./generate.sh --themes         # Generate theme screenshots only
#   ./generate.sh --renderers      # Generate renderer screenshots only
#   ./generate.sh --features       # Generate feature screenshots only
#   ./generate.sh --gifs           # Also generate animated GIFs
#   ./generate.sh --install-deps   # Install VHS, ttyd, and Nerd Font (for CI)
#
# Requirements:
#   - VHS: https://github.com/charmbracelet/vhs
#     Install: go install github.com/charmbracelet/vhs@latest
#             or: brew install vhs
#             or: nix-env -iA nixpkgs.vhs
#   - Neovim (nightly)
#   - fuzzy.so must be built: make -C csrc
#
# Optional:
#   - nvim-web-devicons (auto-cloned to deps/ if missing)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/output"
INIT_LUA="$SCRIPT_DIR/init.lua"
SAMPLE_LUA="$SCRIPT_DIR/sample.lua"

# ── Config lists ───────────────────────────────────────────────────

RENDERER_CONFIGS=(
  popupmenu
  popupmenu_border
  popupmenu_palette
  wildmenu
)

THEME_CONFIGS=(
  theme_auto
  theme_default
  theme_saloon
  theme_outlaw
  theme_sunset
  theme_prairie
  theme_dusty
  theme_midnight
  theme_wanted
  theme_cactus
  theme_tumbleweed
  theme_kanagawa
  theme_kanagawa_dragon
  theme_kanagawa_lotus
)

FEATURE_CONFIGS=(
  devicons
  fuzzy
  gradient
  search
  renderer_mux
)

ALL_CONFIGS=("${RENDERER_CONFIGS[@]}" "${THEME_CONFIGS[@]}" "${FEATURE_CONFIGS[@]}")

# ── Settings ───────────────────────────────────────────────────────

WIDTH=1200
HEIGHT=600
FONT_SIZE=14
FONT_FAMILY="JetBrainsMono Nerd Font"
PADDING=20
VHS_THEME="Catppuccin Mocha"
GENERATE_GIFS=false

# ── CI dependency installer ───────────────────────────────────────

install_deps() {
  echo "Installing CI dependencies..."

  # VHS + ttyd via Charm apt repo
  if ! command -v vhs &>/dev/null; then
    echo "  Installing VHS and ttyd..."
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
      | sudo tee /etc/apt/sources.list.d/charm.list
    sudo apt-get update
    sudo apt-get install -y vhs ttyd
  fi

  # JetBrainsMono Nerd Font
  if ! fc-list | grep -qi "JetBrainsMono Nerd Font"; then
    echo "  Installing JetBrainsMono Nerd Font..."
    mkdir -p ~/.local/share/fonts
    curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
      | tar -xJf - -C ~/.local/share/fonts
    fc-cache -fv
  fi

  echo "  Dependencies installed."
}

# ── Helpers ────────────────────────────────────────────────────────

usage() {
  head -n 16 "$0" | tail -n +2 | sed 's/^# \?//'
  exit 0
}

check_deps() {
  if ! command -v vhs &>/dev/null; then
    echo "Error: VHS is not installed."
    echo ""
    echo "Install VHS:"
    echo "  go install github.com/charmbracelet/vhs@latest"
    echo "  brew install vhs"
    echo "  nix-env -iA nixpkgs.vhs"
    echo ""
    echo "See: https://github.com/charmbracelet/vhs"
    exit 1
  fi

  if ! command -v nvim &>/dev/null; then
    echo "Error: Neovim is not installed."
    exit 1
  fi

  if [ ! -f "$ROOT_DIR/lua/wildest/fuzzy.so" ]; then
    echo "Warning: fuzzy.so not found. Building..."
    make -C "$ROOT_DIR/csrc"
  fi
}

ensure_devicons() {
  local devicons_path="$ROOT_DIR/deps/nvim-web-devicons"
  if [ ! -d "$devicons_path" ]; then
    echo "Cloning nvim-web-devicons..."
    git clone --depth 1 https://github.com/nvim-tree/nvim-web-devicons "$devicons_path"
  fi
}

# Get the cmdline command to type for a config
get_cmd_input() {
  local config="$1"
  case "$config" in
    search)          echo "/function" ;;
    devicons)        echo ":e lua/wildest/" ;;
    fuzzy)           echo ":colo" ;;
    gradient)        echo ":set no" ;;
    renderer_mux)    echo ":set " ;;
    *)               echo ":set " ;;
  esac
}

# Generate a VHS tape for a single config
generate_tape() {
  local config="$1"
  local tape_file="$2"
  local cmd_input
  cmd_input="$(get_cmd_input "$config")"

  # Split into mode char and typed text
  local mode="${cmd_input:0:1}"
  local typed="${cmd_input:1}"

  local nvim_cmd="WILDEST_CONFIG=${config} nvim -u ${INIT_LUA} ${SAMPLE_LUA}"

  {
    # Optionally add GIF output
    if [ "$GENERATE_GIFS" = true ]; then
      echo "Output \"${OUTPUT_DIR}/${config}.gif\""
    fi

    cat <<TAPE
Require nvim

Set Shell "bash"
Set FontSize $FONT_SIZE
Set FontFamily "$FONT_FAMILY"
Set Width $WIDTH
Set Height $HEIGHT
Set Padding $PADDING
Set Theme "$VHS_THEME"
Set TypingSpeed 50ms

Type "${nvim_cmd}"
Enter
Sleep 2s

Type "${mode}"
Sleep 500ms
Type@80ms "${typed}"
Sleep 2s

Screenshot "${OUTPUT_DIR}/${config}.png"

Escape
Sleep 300ms
Type ":q!"
Enter
Sleep 500ms
TAPE
  } >"$tape_file"
}

# Run a single config
run_config() {
  local config="$1"
  local tape_file
  tape_file="$(mktemp /tmp/wildest_screenshot_XXXXXX.tape)"

  echo "  Generating: $config"
  generate_tape "$config" "$tape_file"

  if ! vhs "$tape_file" >/dev/null 2>&1; then
    echo "    FAILED: $config (see above for errors)"
    rm -f "$tape_file"
    return 1
  fi

  rm -f "$tape_file"

  if [ -f "$OUTPUT_DIR/${config}.png" ]; then
    local size
    size="$(du -h "$OUTPUT_DIR/${config}.png" | cut -f1)"
    echo "    OK: ${config}.png ($size)"
  else
    echo "    FAILED: ${config}.png not created"
    return 1
  fi
}

# ── Main ───────────────────────────────────────────────────────────

main() {
  local configs_to_run=()

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h)     usage ;;
      --list)
        echo "Available configs:"
        echo ""
        echo "Renderers:"
        printf "  %s\n" "${RENDERER_CONFIGS[@]}"
        echo ""
        echo "Themes:"
        printf "  %s\n" "${THEME_CONFIGS[@]}"
        echo ""
        echo "Features:"
        printf "  %s\n" "${FEATURE_CONFIGS[@]}"
        exit 0
        ;;
      --themes)      configs_to_run+=("${THEME_CONFIGS[@]}") ;;
      --renderers)   configs_to_run+=("${RENDERER_CONFIGS[@]}") ;;
      --features)    configs_to_run+=("${FEATURE_CONFIGS[@]}") ;;
      --gifs)        GENERATE_GIFS=true ;;
      --install-deps) install_deps ;;
      *)
        # Single config name
        configs_to_run+=("$1")
        ;;
    esac
    shift
  done

  # Default: all configs
  if [ ${#configs_to_run[@]} -eq 0 ]; then
    configs_to_run=("${ALL_CONFIGS[@]}")
  fi

  check_deps
  ensure_devicons
  mkdir -p "$OUTPUT_DIR"

  echo "Generating ${#configs_to_run[@]} screenshot(s)..."
  echo "Output: $OUTPUT_DIR/"
  echo ""

  local failed=0
  local succeeded=0

  for config in "${configs_to_run[@]}"; do
    if run_config "$config"; then
      succeeded=$((succeeded + 1))
    else
      failed=$((failed + 1))
    fi
  done

  echo ""
  echo "Done: $succeeded succeeded, $failed failed"
  echo "Screenshots: $OUTPUT_DIR/"
}

main "$@"
