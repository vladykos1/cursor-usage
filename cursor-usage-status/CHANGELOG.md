# Changelog

## 0.1.1 — initial public release

- Status bar item showing **Total (Included in Pro)**, **Auto + Composer** and **API (named)** usage from `cursor.com/api/usage-summary`.
- Commands: *Refresh now*, *Set session token…*, *Open dashboard*.
- Settings: `cursorUsageStatus.sessionToken`, `cursorUsageStatus.refreshIntervalMinutes` (1–120).
- Tooltip with billing cycle end date and link to the official dashboard.
- Token sources: User settings, environment variable `CURSOR_SESSION_TOKEN`.
- VSIX packaging for easy install via *Extensions: Install from VSIX…*.
