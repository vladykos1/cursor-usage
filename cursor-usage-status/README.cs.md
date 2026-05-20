# Cursor plan usage (stavový řádek)

> 🇬🇧 **English version:** [README.md](./README.md) · Kořen projektu: [hlavní README](../README.cs.md)

Přidává do **stavového řádku** Cursoru / VS Code položku s **Total**, **Auto + Composer** a **API (named)** spotřebou. Data z `https://cursor.com/api/usage-summary` (stejně jako oficiální dashboard).

![Náhled status baru](../docs/status-bar-preview.png)

## Rychlá instalace

**VSIX (doporučeno):** stáhni si nejnovější `.vsix` ze záložky [GitHub Releases](../../../releases) → v Cursoru otevři panel **Extensions** → `…` → **Install from VSIX…** → vyber stažený soubor.

**Ze zdrojáků:** zkopíruj `extension.js` + `package.json` do:  
   `%USERPROFILE%\.cursor\extensions\lukasvladyka.cursor-usage-status-0.1.1`  
   (název složky **musí** odpovídat `publisher.název-verze` v `package.json`), pak **Developer: Reload Window**.

Pro vývoj otevři tuto složku v Cursoru a stiskni **F5**.

## Nastavení session tokenu

`Ctrl+Shift+P` → **Cursor usage: Set session token…** → vlož hodnotu cookie `WorkosCursorSessionToken` z přihlášené session na [cursor.com](https://cursor.com) (DevTools → Application → Cookies).

Token se uloží do **User Settings** pod klíč `cursorUsageStatus.sessionToken`. Necommituj ho.

## Nastavení

| Klíč | Výchozí | Význam |
|------|---------|--------|
| `cursorUsageStatus.sessionToken` | prázdné | Hodnota session cookie (User settings). |
| `cursorUsageStatus.refreshIntervalMinutes` | `5` | Interval obnovení v minutách (1–120). |

## Příkazy

| Příkaz | Účel |
|--------|------|
| `Cursor usage: Refresh now` | Okamžité obnovení (stejné jako klik na položku ve status baru). |
| `Cursor usage: Set session token…` | Vložení tokenu (maskovaný input). |
| `Cursor usage: Open dashboard` | Otevře [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage). |

## Řešení problémů

- **Oranžová „set token“** — token ještě není nastavený.
- **Červený status / HTTP 401** — token vypršel; obnov v prohlížeči a znovu spusť *Set session token*.
- **Status bar nevidím** — `View → Appearance → Status Bar`.
- **Endpoint** je neoficiální — když Cursor změní formát odpovědi, parser bude potřeba upravit.

Kompletní dokumentace: [hlavní README (CZ)](../README.cs.md).
