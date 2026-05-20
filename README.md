# Cursor usage helpers (Windows)

> 🇨🇿 **Česká verze:** [README.cs.md](./README.cs.md)

Small **unofficial** tools that show **Total (Included in Pro)**, **Auto + Composer** and **API (named)** usage from the same data Cursor uses on the web (`GET https://cursor.com/api/usage-summary` with cookie `WorkosCursorSessionToken`).

| Tool | What it does |
|------|--------------|
| **[`cursor-usage-status/`](./cursor-usage-status/)** | Cursor / VS Code **extension** — live **status bar** `Total % · Auto % · API %` (recommended) |
| **[`cursor-usage.ps1`](./cursor-usage.ps1)** | **PowerShell** terminal script with optional watch mode and Windows notifications |

Inspired by [cursor-usage-menubar](https://github.com/vokal-pe/cursor-usage-menubar) (macOS menu bar). This repo targets **Windows** and **in-editor** visibility.

> **Disclaimer:** The endpoint is not a documented public API; it may change. **Do not commit or share your session token.** This project is not affiliated with Cursor.

![Status bar showing Total, Auto and API usage with tooltip detail](./docs/status-bar-preview.png)

*Status bar item (bottom) and tooltip — **Total** matches *Included in Pro* in Cursor settings; Auto + Composer and API are the pool breakdown.*

---

## Status bar extension (inside Cursor)

The built-in **“context used”** ring in the Agent UI **cannot** be replaced or extended; the status bar is the supported place for custom usage text.

### Install

**Option A — VSIX (recommended, easiest):**

1. Download the latest **`cursor-usage-status-*.vsix`** from the [GitHub Releases](../../releases) page.
2. In Cursor: open the **Extensions** panel → click `…` (top-right) → **Install from VSIX…** → pick the file.
3. **Developer: Reload Window** if needed.

**Option B — From source (for development / F5 debugging):**

- Open [`cursor-usage-status/`](./cursor-usage-status/) in Cursor and press **F5** — a new *Extension Development Host* window opens with the status bar item already loaded.

**Option C — Copy files manually:**

- Copy `extension.js` + `package.json` (and optionally `README.md`) into your extensions folder:  
  `%USERPROFILE%\.cursor\extensions\lukasvladyka.cursor-usage-status-0.1.1`  
  Folder name must match `publisher.name-version` from `package.json`. Then restart Cursor or run **Developer: Reload Window**.

### Set session token (Command Palette) — the usual first step

1. Get cookie **`WorkosCursorSessionToken`** from your browser while logged in at [cursor.com](https://cursor.com): DevTools → **Application** → **Cookies** → `cursor.com`. Copy the **Value** (long string — treat like a password).
2. In Cursor press **Ctrl+Shift+P** (macOS: **Cmd+Shift+P**).
3. Type **`Cursor usage: Set session token`** and choose **Cursor usage: Set session token…**.
4. A **small input field** appears at the top (masked like a password). **Paste the cookie value** and press Enter.

> **If you see a list of project files** (e.g. `cursor-usage.ps1`) instead of a paste box, you opened the file quick-open instead of the command — close it, open Command Palette again with **Ctrl+Shift+P**, and pick the command from the list.

**Alternative ways to set the token**

- **User Settings:** search for `cursorUsageStatus.sessionToken` and paste there (User scope — never workspace).
- **Environment:** `CURSOR_SESSION_TOKEN` set before launching Cursor.

After setting the token the status bar should show e.g. `Total 6% · Auto 4% · API 13%`. Click the item to refresh; hover for a detailed tooltip with cycle end date and a link to the dashboard.

### Extension settings

| Key | Default | Meaning |
|-----|---------|---------|
| `cursorUsageStatus.sessionToken` | empty | Session cookie value (User settings). |
| `cursorUsageStatus.refreshIntervalMinutes` | `5` | Polling interval (1–120). |

### Commands

| Command | Purpose |
|---------|---------|
| `Cursor usage: Refresh now` | Refresh immediately (also: click the status bar item). |
| `Cursor usage: Set session token…` | Paste the cookie value (masked input). |
| `Cursor usage: Open dashboard` | Opens [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage). |

---

## PowerShell script

Same API as above. Token sources (order):

1. `-SessionToken` parameter  
2. Environment variable **`CURSOR_SESSION_TOKEN`** (process scope)  
3. **`%USERPROFILE%\.cursor-usage\config.json`**: `{ "session_token": "..." }`

```powershell
cd path\to\Cursor_usage
.\cursor-usage.ps1                                  # one-shot
.\cursor-usage.ps1 -Watch                           # refresh every 5 min
.\cursor-usage.ps1 -Watch -IntervalSeconds 600 -NotifyAtPercent 0
```

The PowerShell script and the extension do **not** share storage — the script reads env / `.cursor-usage/config.json`, the extension reads VS Code settings. Same cookie value, two locations.

Local secrets stay in `.gitignore` (`.cursor-usage/`, `*.local.json`, `.env*`).

---

## Getting `WorkosCursorSessionToken` from the browser

1. Log in at https://cursor.com in **Chrome / Edge / Firefox**.  
2. **F12** → **Application** (or Storage) → **Cookies** → `https://cursor.com`.  
3. Find **`WorkosCursorSessionToken`** → copy the **Value**.

Never paste this token into issues, chats, or commits.

---

## Limits & notes

- Billing is **monthly** with two pools (Auto + Composer vs API). Don’t expect Claude-style daily/weekly sliders from this API.
- On **HTTP 401/403** the extension shows a red status item — refresh the token from the browser.
- The endpoint is unofficial; if Cursor changes the response shape the parser may need an update.

---

## Author

**Lukáš Vladyka**  
- Email: [vladykosss@gmail.com](mailto:vladykosss@gmail.com)  
- LinkedIn: [linkedin.com/in/lukáš-vladyka](https://www.linkedin.com/in/luk%C3%A1%C5%A1-vladyka/)

## License

[MIT](./LICENSE)
