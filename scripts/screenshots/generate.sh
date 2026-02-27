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
#   ./generate.sh --pipelines      # Generate pipeline screenshots only
#   ./generate.sh --layouts        # Generate layout screenshots only
#   ./generate.sh --options        # Generate renderer option screenshots only
#   ./generate.sh --gifs           # Also generate animated GIFs
#   ./generate.sh --showdown        # Generate the animated showdown GIF only
#   ./generate.sh -j4              # Run 4 screenshots in parallel
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
  theme_catppuccin_mocha
  theme_catppuccin_frappe
  theme_catppuccin_latte
  theme_tokyonight_night
  theme_tokyonight_storm
  theme_tokyonight_moon
  theme_rose_pine
  theme_rose_pine_moon
  theme_rose_pine_dawn
  theme_gruvbox_dark
  theme_gruvbox_light
  theme_nord
  theme_onedark
  theme_nightfox
  theme_everforest_dark
  theme_everforest_light
  theme_dracula
  theme_solarized_dark
)

FEATURE_CONFIGS=(
  devicons
  fuzzy
  gradient
  search
  renderer_mux
  kind_icons
)

PIPELINE_CONFIGS=(
  lua_pipeline
  help_pipeline
  history_pipeline
)

HIGHLIGHT_CONFIGS=(
  hl_neon
  hl_ember
  hl_ocean
)

LAYOUT_CONFIGS=(
  laststatus_0
  laststatus_2
  laststatus_3
  cmdheight_0
  cmdheight_0_offset_1
  cmdheight_0_offset_2
  offset_1
  offset_2
)

OPTION_CONFIGS=(
  noselect_false
  reverse
  empty_message
  buffer_flags
)

ALL_CONFIGS=("${RENDERER_CONFIGS[@]}" "${THEME_CONFIGS[@]}" "${FEATURE_CONFIGS[@]}" "${PIPELINE_CONFIGS[@]}" "${HIGHLIGHT_CONFIGS[@]}" "${LAYOUT_CONFIGS[@]}" "${OPTION_CONFIGS[@]}")

# ── Settings ───────────────────────────────────────────────────────

PARALLEL_JOBS=1
WIDTH=1200
HEIGHT=600
FONT_SIZE=14
FONT_FAMILY="JetBrainsMono Nerd Font"
PADDING=20
VHS_THEME="Catppuccin Mocha"
GENERATE_GIFS=false
GENERATE_SHOWDOWN=false

# ── Showdown scenes ──────────────────────────────────────────────
# The showdown GIF uses a hard-coded tape (see generate_showdown) so
# there is no SHOWDOWN_CONFIGS array — scene commands live in the tape.

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
    fuzzy)           echo ":help win" ;;
    gradient)        echo ":help help-" ;;
    renderer_mux)    echo ":set fold" ;;
    lua_pipeline)    echo ":lua vim.api.nvim" ;;
    help_pipeline)   echo ":help nvim_b" ;;
    history_pipeline) echo ":set fold" ;;
    kind_icons)      echo ":set fold" ;;
    hl_neon)         echo ":set fold" ;;
    empty_message)   echo ":zzzznotacommand" ;;
    buffer_flags)    echo ":b " ;;
    *)               echo ":set fold" ;;
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

  local nvim_cmd="WILDEST_CONFIG=${config} nvim -u ${INIT_LUA} -i NONE ${SAMPLE_LUA}"

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

# Generate the animated showdown GIF (single nvim session, 4 packed scenes)
generate_showdown() {
  echo "Generating animated showdown GIF..."

  local showdown_init="$SCRIPT_DIR/showdown_init.lua"
  local tape_file
  tape_file="$(mktemp /tmp/wildest_showdown_XXXXXX.tape)"

  cat >"$tape_file" <<TAPE
Output "${OUTPUT_DIR}/showdown.gif"

Require nvim

Set Shell "bash"
Set FontSize $FONT_SIZE
Set FontFamily "$FONT_FAMILY"
Set Width $WIDTH
Set Height $HEIGHT
Set Padding $PADDING
Set Theme "$VHS_THEME"
Set TypingSpeed 60ms

Hide
Type "nvim -u ${showdown_init} -i NONE ${SAMPLE_LUA}"
Enter
Sleep 2s
Show

# ── Scene 1: Popupmenu + Devicons + Kind Icons + Fzy ──
Type ":"
Sleep 300ms
Type@80ms "e lua/wildest/"
Sleep 2s
Escape
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "help nvim_b"
Sleep 2s
Escape
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "lua vim.api.nvim"
Sleep 2s
Escape
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "set fold"
Sleep 2s
Escape
Sleep 300ms

# ── Scene 2: Palette + Gradient Rainbow ──
Ctrl+n
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "help help-"
Sleep 2s
Escape
Sleep 300ms

# ── Scene 3: Wildmenu + Search ──
Ctrl+n
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "set fold"
Sleep 2s
Escape
Sleep 300ms

Type "/"
Sleep 300ms
Type@80ms "function"
Sleep 2s
Escape
Sleep 300ms

# ── Scene 4: Neon Theme ──
Ctrl+n
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "e lua/wildest/"
Sleep 2s
Escape
Sleep 300ms

Type ":"
Sleep 300ms
Type@80ms "set fold"
Sleep 2s
Escape
Sleep 300ms

Hide
Type ":q!"
Enter
Sleep 500ms
TAPE

  if vhs "$tape_file" 2>&1; then
    local size
    size="$(du -h "$OUTPUT_DIR/showdown.gif" | cut -f1)"
    echo "  OK: showdown.gif ($size)"
  else
    echo "  FAILED: showdown.gif"
    rm -f "$tape_file"
    return 1
  fi

  rm -f "$tape_file"
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
        echo ""
        echo "Pipelines:"
        printf "  %s\n" "${PIPELINE_CONFIGS[@]}"
        echo ""
        echo "Highlights:"
        printf "  %s\n" "${HIGHLIGHT_CONFIGS[@]}"
        echo ""
        echo "Layouts:"
        printf "  %s\n" "${LAYOUT_CONFIGS[@]}"
        echo ""
        echo "Options:"
        printf "  %s\n" "${OPTION_CONFIGS[@]}"
        exit 0
        ;;
      --themes)      configs_to_run+=("${THEME_CONFIGS[@]}") ;;
      --renderers)   configs_to_run+=("${RENDERER_CONFIGS[@]}") ;;
      --features)    configs_to_run+=("${FEATURE_CONFIGS[@]}") ;;
      --pipelines)   configs_to_run+=("${PIPELINE_CONFIGS[@]}") ;;
      --highlights)  configs_to_run+=("${HIGHLIGHT_CONFIGS[@]}") ;;
      --layouts)     configs_to_run+=("${LAYOUT_CONFIGS[@]}") ;;
      --options)     configs_to_run+=("${OPTION_CONFIGS[@]}") ;;
      --gifs)        GENERATE_GIFS=true ;;
      --showdown)    GENERATE_SHOWDOWN=true ;;
      -j*)           PARALLEL_JOBS="${1#-j}" ;;
      --install-deps) install_deps ;;
      *)
        # Single config name
        configs_to_run+=("$1")
        ;;
    esac
    shift
  done

  # Default: all configs
  if [ ${#configs_to_run[@]} -eq 0 ] && [ "$GENERATE_SHOWDOWN" = false ]; then
    configs_to_run=("${ALL_CONFIGS[@]}")
  fi

  check_deps
  ensure_devicons
  mkdir -p "$OUTPUT_DIR"

  # Showdown-only mode: just generate the showdown GIF and exit
  if [ "$GENERATE_SHOWDOWN" = true ] && [ ${#configs_to_run[@]} -eq 0 ]; then
    generate_showdown
    echo ""
    echo "Output: $OUTPUT_DIR/"
    exit 0
  fi

  echo "Generating ${#configs_to_run[@]} screenshot(s) (jobs: $PARALLEL_JOBS)..."
  echo "Output: $OUTPUT_DIR/"
  echo ""

  if [ "$PARALLEL_JOBS" -gt 1 ] 2>/dev/null; then
    # Export everything the child processes need
    export OUTPUT_DIR INIT_LUA SAMPLE_LUA GENERATE_GIFS
    export WIDTH HEIGHT FONT_SIZE FONT_FAMILY PADDING VHS_THEME

    export -f generate_tape run_config get_cmd_input

    printf '%s\n' "${configs_to_run[@]}" \
      | xargs -P "$PARALLEL_JOBS" -I {} bash -c 'run_config "$@"' _ {}

    local succeeded=0 failed=0
    for config in "${configs_to_run[@]}"; do
      if [ -f "$OUTPUT_DIR/${config}.png" ]; then
        succeeded=$((succeeded + 1))
      else
        failed=$((failed + 1))
      fi
    done
  else
    local failed=0
    local succeeded=0

    for config in "${configs_to_run[@]}"; do
      if run_config "$config"; then
        succeeded=$((succeeded + 1))
      else
        failed=$((failed + 1))
      fi
    done
  fi

  echo ""
  echo "Done: $succeeded succeeded, $failed failed"
  echo "Screenshots: $OUTPUT_DIR/"

  # Generate showdown GIF if requested alongside screenshots
  if [ "$GENERATE_SHOWDOWN" = true ]; then
    generate_showdown
  fi
}

main "$@"
