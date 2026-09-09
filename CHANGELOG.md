# Changelog

All notable changes to this fork of
[eyebrowse](https://depp.brause.cc/eyebrowse) since the last upstream release
(0.7.8).

## Unreleased

### Added

- `eyebrowse-indicator-target` selects the mode line (the default), header line,
  frame title, or manual placement (`nil`).
- Cached plain-text `eyebrowse-indicator-string` for frame titles and manual
  placement, with `eyebrowse-indicator-format` for padding or separators.

### Changed

- With `eyebrowse-persist-window-configs`, window configs are also saved
  whenever `desktop-save` runs, not only on exit, so they survive an unexpected
  quit when `desktop-save-mode` auto-saves.

## 0.9.0 (2026-09-07)

### Added

- **Per-workspace winner histories** (`eyebrowse-winner-integration`, default
  on): each window config keeps its own `winner-undo` ring, the way
  `tab-bar-history-mode` keeps one per tab.
- **Persistence across restarts**: window configs are saved as serializable
  window states and restored on startup.  Pairs well with `desktop-save-mode`,
  which brings back the buffers the configs refer to.
- **Cloning**: clone the current config into the next slot, shifting neighbors
  up to make room.  The clone inherits the tag and the winner history.
- **Dragging** and swapping: reorder workspaces by trading places with a
  neighbor instead of renumbering everything.
- Switch commands for slots 10–19.
- Tag auto-suggestion when renaming, with a history of used tags persisted in
  `eyebrowse-known-tags-file`.
- Mode-line: repeated subsequent tags display a marker instead of a tag that
  repeats the previous config's tag.

### Changed

- Minimum Emacs is now declared as 27.1 in `Package-Requires` (required in
  practice since 0.8.0).
- `eyebrowse-move-window-config` refuses to overwrite the currently displayed
  window config (error state).
- The rename prompt no longer pre-fills the old tag, so submitting empty input
  clears the tag.

### Fixed

- Stored window configs are no longer destructively rewritten when a slot is
  displayed before its buffers exist (e.g. right after a desktop restore).  Dead
  buffers are fixed up on a copy of the stored config.
- A window-layout change made by the very command that switches workspaces is
  recorded into the old workspace's winner history instead of being lost.

### Inherited from upstream

- Move and renumber commands (`eyebrowse-move-window-config`,
  `eyebrowse-renumber-window-configs`).
- `eyebrowse-mode-prefix-map` defined as a global variable.

## 0.8.0 (2023-12-28)

### Added

- `eyebrowse-indicator-change-hook` and current-config delimiters, so indicators
  outside the mode line (e.g. the frame title) can track state changes without
  polling.

### Changed

- Focus handling uses `after-focus-change-function` (Emacs 27.1+).

### Inherited from upstream

- `eyebrowse-post-window-delete-hook`.
- `eyebrowse-create-named-window-config`.
- Guard against switching when there is no previous/next window config.
