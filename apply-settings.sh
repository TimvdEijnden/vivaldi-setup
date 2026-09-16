#!/usr/bin/env bash
#
# Apply vivaldi-settings.json to the local Vivaldi profile.
#
# Merges the settings snapshot from this repo into the profile's `Preferences`
# file (after backing it up) and points Vivaldi's Custom UI Modifications
# directory at this repo.
#
# Usage:
#   ./apply-settings.sh [--profile NAME] [--prefs PATH] [--dry-run] [--force]
#
# Options:
#   --profile NAME  Profile directory to use (default: Default)
#   --prefs PATH    Explicit path to the Preferences file (overrides --profile)
#   --dry-run       Show what would happen without modifying anything
#   --force         Apply even if Vivaldi appears to be running (not advised)
#   -h, --help      Show this help
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_FILE="$SCRIPT_DIR/vivaldi-settings.json"
PROFILE="Default"
PREFS=""
DRY_RUN=0
FORCE=0

usage() {
  cat <<'EOF'
Apply vivaldi-settings.json to the local Vivaldi profile.

Merges the settings snapshot from this repo into the profile's `Preferences`
file (after backing it up) and points Vivaldi's Custom UI Modifications
directory at this repo.

Usage:
  ./apply-settings.sh [--profile NAME] [--prefs PATH] [--dry-run] [--force]

Options:
  --profile NAME  Profile directory to use (default: Default)
  --prefs PATH    Explicit path to the Preferences file (overrides --profile)
  --dry-run       Show what would happen without modifying anything
  --force         Apply even if Vivaldi appears to be running (not advised)
  -h, --help      Show this help
EOF
  exit "${1:-0}"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --profile) PROFILE="${2:?--profile needs a value}"; shift 2 ;;
    --prefs)   PREFS="${2:?--prefs needs a value}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force)   FORCE=1; shift ;;
    -h|--help) usage 0 ;;
    *) echo "Unknown option: $1" >&2; usage 1 ;;
  esac
done

say()  { printf '%s\n' "$*"; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq is required but was not found in PATH."
[ -f "$SETTINGS_FILE" ] || die "settings file not found: $SETTINGS_FILE"

# --- locate the Preferences file -------------------------------------------
if [ -z "$PREFS" ]; then
  case "$(uname -s)" in
    Darwin)
      PREFS="$HOME/Library/Application Support/Vivaldi/$PROFILE/Preferences" ;;
    Linux)
      PREFS="$HOME/.config/vivaldi/$PROFILE/Preferences" ;;
    MINGW*|MSYS*|CYGWIN*)
      WINROAMING="${APPDATA:-$HOME/AppData/Roaming}"
      PREFS="$WINROAMING/../Local/Vivaldi/User Data/$PROFILE/Preferences" ;;
    *)
      die "unsupported OS '$(uname -s)'; pass --prefs PATH explicitly." ;;
  esac
fi

[ -f "$PREFS" ] || die "Preferences file not found: $PREFS
Is Vivaldi installed and has it been started at least once?"

# --- make sure Vivaldi is not running --------------------------------------
vivaldi_running() {
  if command -v pgrep >/dev/null 2>&1; then
    pgrep -x "Vivaldi" >/dev/null 2>&1 && return 0
    pgrep -x "vivaldi-bin" >/dev/null 2>&1 && return 0
    pgrep -x "vivaldi" >/dev/null 2>&1 && return 0
  fi
  return 1
}

if vivaldi_running && [ "$FORCE" -ne 1 ]; then
  die "Vivaldi appears to be running.
Quit Vivaldi completely (including background processes) and re-run this script,
or pass --force to override (your changes may be lost when Vivaldi exits)."
fi

say "Repo:        $SCRIPT_DIR"
say "Settings:    $SETTINGS_FILE"
say "Preferences: $PREFS"
[ "$FORCE" -eq 1 ] && say "Force:       on (Vivaldi may be running)"
say ""

# --- validate the settings snapshot ----------------------------------------
jq -e '.vivaldi' "$SETTINGS_FILE" >/dev/null 2>&1 \
  || die "$SETTINGS_FILE is not valid JSON with a top-level 'vivaldi' key."

# --- merge into a temp file in the same directory (atomic-ish) --------------
TMP="$(mktemp "$(dirname "$PREFS")/.Preferences.XXXXXX")"
trap 'rm -f "$TMP"' EXIT

jq -s --arg cssdir "$SCRIPT_DIR" \
  '.[0] * (.[1] | .vivaldi.appearance.css_ui_mods_directory = $cssdir)' \
  "$PREFS" "$SETTINGS_FILE" > "$TMP"

jq -e . "$TMP" >/dev/null 2>&1 || die "merge produced invalid JSON; Preferences left untouched."

if [ "$DRY_RUN" -eq 1 ]; then
  say "Dry run: merge is valid. Would have:"
  say "  - backed up $PREFS"
  say "  - applied settings and set css_ui_mods_directory to $SCRIPT_DIR"
  rm -f "$TMP"
  exit 0
fi

# --- back up and swap in the merged file -----------------------------------
BACKUP="$PREFS.bak.$(date +%Y%m%d%H%M%S)"
cp -p "$PREFS" "$BACKUP"
say "Backed up:   $BACKUP"

mv "$TMP" "$PREFS"
trap - EXIT
say "Applied:     $PREFS"
say ""
say "Custom UI Modifications directory set to:"
say "  $SCRIPT_DIR"
say "$(printf '%s\n' "It loads every .css file in that folder (custom-styles.css).")"
say ""
say "Restart Vivaldi for the changes to take effect."
