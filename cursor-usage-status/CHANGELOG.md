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

1. Uninstall: `cursor --uninstall-extension lukasvladyka.cursor-usage-status` (or Extensions panel → Uninstall).
2. Optionally also `cursor --uninstall-extension local.cursor-usage-status` — only if you copied files manually with publisher `local`. *Extension is not installed* here is OK.
3. If still broken, run [`reset-cursor-usage-extension.ps1`](../reset-cursor-usage-extension.ps1) with Cursor fully closed.
4. Install the same `.vsix` again via Command Palette.

See the [main README](../README.md) for full **Uninstall, cleanup, and reinstall** steps.
