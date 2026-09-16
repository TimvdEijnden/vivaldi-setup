# Vivaldi configuration

A portable snapshot of my Vivaldi browser configuration, so it can be reproduced on
another machine.

## Contents

| File                   | Purpose                                                              |
| ---------------------- | -------------------------------------------------------------------- |
| `custom-styles.css`    | Custom UI Modifications stylesheet (vertical tabs layout).           |
| `vivaldi-settings.json`| Sanitized snapshot of Vivaldi's `vivaldi.*` preferences + `intl`.    |
| `apply-settings.sh`    | Script that backs up and merges the settings into a local profile.  |

## Privacy

This repo is public, so everything personal has been stripped out. The settings
snapshot contains **no** account credentials, device IDs, bookmarks, history,
saved locations, notes content, extension IDs, usage/telemetry data or absolute
user paths. See [What is intentionally omitted](#what-is-intentionally-omitted).

---

## Current configuration

### Layout (active layout: `vertical`)

- **Tab bar**: vertical, on the left, 287 px wide
- **Address bar**: off (hidden)
- **Panel**: on the right, default panel is the Window panel, 400 px wide
- **Status bar**: overlay
- **Auto-hide UI**: enabled (panel auto-hides)
- **UI density**: compact
- **Tab stacks**: dotted
- **Start page navigation**: Speed Dial only
- **Title bar**: hidden
- **Bookmark bar**: hidden

### Tabs

- Tab separators shown
- Tab notification/counter detection on
- Tab stacking mode `1`, drag-and-drop stacking delay 450 ms
- Permanent close buttons off
- Tabs visible

### Appearance & theme

- Compact UI density
- Custom toolbar buttons preferred
- Theme schedule enabled:
  - Dark: `VivaldiForest`
  - Light: `Vivaldi1`
- Force dark mode theme: off
- Translate: enabled

### Panels (right side, in order)

Bookmarks, Downloads, History, Notes, Translate, Window, Reading list, divider,
Mail, Contacts, Calendar, Tasks, Feeds, then web panels
(Vivaldi Social, Vivaldi Help, Wikipedia) and the Bitwarden extension panel,
Web panel, and a flexible spacer.

Panel behaviour: lazy loading on, close button shown, folder badges shown,
toggle shown.

### Toolbars

- **Tab bar (before)**: Workspace button, Tab button, Extensions, Back, Reload, Forward, Address field
- **Tab bar (after)**: New tab, Account button, VPN button, Update button
- **Status bar**: Settings, Break mode, Sync status, Mail status, Calendar status, Status info, Version info, Auto-hide toggle, Capture images, Tiling toggle, Page actions, Zoom, Clock

### Keyboard shortcuts, mouse gestures & command chains

All custom keyboard shortcuts, mouse gestures and command chains are stored under
`vivaldi.actions` and `vivaldi.chained_commands` in `vivaldi-settings.json`.

### Language

- Accept languages: `en-US,en,nl`
- UI language: `en-GB`

### Search

- Default search engine: built-in provider `Google` (index 5)

---

## How to apply on another machine

Vivaldi has no built-in "import settings file" button. There are two ways to
reproduce this configuration.

### Option A — Vivaldi Sync (easiest)

Log into the same Vivaldi account on the other machine and enable **Settings →
Sync**, including *Settings*. Most of the above is synced automatically.

### Option B — Apply the files manually

1. **Clone this repo** somewhere on the other machine, e.g. `~/vivaldi`.

2. **Quit Vivaldi completely**, then run the apply script. It backs up your
   existing `Preferences`, merges in the snapshot, and points the Custom UI
   Modifications directory at the cloned repo.

   ```sh
   cd ~/vivaldi
   ./apply-settings.sh --dry-run   # optional: preview
   ./apply-settings.sh
   ```

   It needs [`jq`](https://jqlang.github.io/jq/). Useful flags:

   | Flag             | Meaning                                              |
   | ---------------- | --------------------------------------------------- |
   | `--profile NAME` | Profile directory to use (default `Default`)        |
   | `--prefs PATH`   | Explicit path to the `Preferences` file             |
   | `--dry-run`      | Validate and report without changing anything       |
   | `--force`        | Apply even if Vivaldi is still running (not advised)|

3. **Restart Vivaldi.**

#### Manual alternative

If you'd rather do it by hand, with Vivaldi closed:

```sh
PREFS="$HOME/Library/Application Support/Vivaldi/Default/Preferences"   # adjust per OS
cp "$PREFS" "$PREFS.bak"
jq -s '.[0] * .[1]' "$PREFS" vivaldi-settings.json > "$PREFS.new" \
  && mv "$PREFS.new" "$PREFS"
```

Profile locations:
- macOS: `~/Library/Application Support/Vivaldi/Default/Preferences`
- Linux: `~/.config/vivaldi/Default/Preferences`
- Windows: `%LOCALAPPDATA%\Vivaldi\User Data\Default\Preferences`

> Note: `vivaldi-settings.json` points `css_ui_mods_directory` at a placeholder
> (`<PATH_TO_THIS_REPO>`). The script replaces it with the repo path; if you merge
> by hand, set it afterwards in Vivaldi's Custom UI Modifications setting.

---

## What is intentionally omitted

To keep the public snapshot safe, the following were removed from the source
`Preferences`:

- `vivaldi.vivaldi_account` — account id, username, device id and refresh token
- `vivaldi.startup` — usage days, version history, keystore canary
- `vivaldi.welcome`, `vivaldi.quick_commands` — onboarding state
- `vivaldi.list`, `vivaldi.settings` — UI selection and window geometry
- `vivaldi.privacy`, `vivaldi.sessions` — timestamps and session state
- `vivaldi.geolocation` — saved cities/coordinates
- `vivaldi.dashboard` — widgets tied to personal bookmark folders
- `vivaldi.bookmarks.deleted_partners` — internal bookmark UUIDs
- `vivaldi.address_bar.extensions` — local extension IDs
- absolute user paths (replaced with placeholders)

Use Vivaldi Sync to move bookmarks, history, passwords and notes.
