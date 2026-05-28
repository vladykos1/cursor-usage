# Changelog

## 0.1.1 — initial public release

- Status bar item showing **Total (Included in Pro)**, **Auto + Composer** and **API (named)** usage from `cursor.com/api/usage-summary`.
- Commands: *Refresh now*, *Set session token…*, *Open dashboard*.
- Settings: `cursorUsageStatus.sessionToken`, `cursorUsageStatus.refreshIntervalMinutes` (1–120).
- Tooltip with billing cycle end date and link to the official dashboard.
- Token sources: User settings, environment variable `CURSOR_SESSION_TOKEN`.
- VSIX packaging for easy install via *Extensions: Install from VSIX…*.

### Install notes (same VSIX — no re-download required)

If reinstall fails with *“Please restart VS Code before reinstalling Cursor plan usage (status bar).”*:

1. Uninstall any existing *Cursor plan usage* entry in Extensions (including old **`local`** publisher).
2. Fully quit Cursor (not just Reload Window).
3. Run [`reset-cursor-usage-extension.ps1`](../reset-cursor-usage-extension.ps1) from the repo, or `cursor --uninstall-extension` for both `local.cursor-usage-status` and `lukasvladyka.cursor-usage-status`.
4. Install the same `.vsix` again via Command Palette.

See the [main README](../README.md) for full troubleshooting.
