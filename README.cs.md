# Cursor usage helpers (Windows)

> 🇬🇧 **English version:** [README.md](./README.md)

Drobné **neoficiální** nástroje, které ukazují **Total (Included in Pro)**, **Auto + Composer** a **API (named)** spotřebu plánu Cursor — stejná data, která ukazuje [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage). Pod kapotou se volá `GET https://cursor.com/api/usage-summary` s cookie `WorkosCursorSessionToken`.

| Nástroj | Co dělá |
|---------|---------|
| **[`cursor-usage-status/`](./cursor-usage-status/)** | **Rozšíření** do Cursoru / VS Code — živý **stavový řádek** `Total % · Auto % · API %` (doporučeno) |
| **[`cursor-usage.ps1`](./cursor-usage.ps1)** | **PowerShell** skript do terminálu s volitelným režimem sledování a Windows notifikacemi |

Inspirováno projektem [cursor-usage-menubar](https://github.com/vokal-pe/cursor-usage-menubar) (macOS menu bar). Tenhle repozitář cílí na **Windows** a **viditelnost přímo v editoru**.

> **Upozornění:** Endpoint není dokumentované veřejné API Cursoru; může se kdykoliv změnit. **Nikdy necommituj ani nesdílej svůj session token.** Projekt není napojený na Cursor.

![Stavový řádek s Total, Auto a API využitím a detailem v tooltipu](./docs/status-bar-preview.png)

*Položka ve status baru (dole) a tooltip — **Total** odpovídá *Included in Pro* v nastavení Cursoru; Auto + Composer a API jsou rozpad poolů.*

---

## Rozšíření do status baru (uvnitř Cursoru)

Kolečko **„context used“** v hlavičce agenta **rozšíření nemůžou** přepsat ani vedle něj přidat vlastní widget — to je vestavěné UI Cursoru. **Status bar** dole je oficiálně podporované místo, kde můžeš mít limity pořád na očích.

### Instalace

**Možnost A — VSIX přes Command Palette (doporučeno, nejrychlejší):**

1. Stáhni si nejnovější **`cursor-usage-status-*.vsix`** ze záložky [GitHub Releases](../../releases).
2. V Cursoru stiskni **Ctrl+Shift+P** a napiš **`Extensions: Install from VSIX...`** — vyber tento příkaz z palety.
3. V dialogu vyber stažený `.vsix` soubor.
4. Pokud se položka ve status baru hned neobjeví, znovu stiskni **Ctrl+Shift+P**, napiš **`Developer: Reload Window`** a vyber tento příkaz.

> Tímhle se vyhneš hledání `…` tlačítka v hlavičce panelu Extensions (které je skryté, když je panel úzký). Command Palette funguje spolehlivě bez ohledu na šířku okna.

**Možnost B — Ze zdrojáků (pro vývoj / F5 ladění):**

- Otevři složku [`cursor-usage-status/`](./cursor-usage-status/) v Cursoru a stiskni **F5** — otevře se nové okno *Extension Development Host* s rozšířením.

**Možnost C — Kopírovat ručně (jen F5 dev, ne pro běžnou instalaci):**

- Pouze pro lokální ladění rozšíření — **nepoužívej** místo VSIX pro normální instalaci. Kopírování obchází Uninstall a často později rozbije přeinstalaci.
- Zkopíruj `extension.js` + `package.json` do složky rozšíření. Název složky musí odpovídat `{publisher}.{název}-{verze}` z [`package.json`](./cursor-usage-status/package.json) (např. `lukasvladyka.cursor-usage-status-0.1.1` u aktuální verze).
- **Windows:** `%USERPROFILE%\.cursor\extensions\` · **macOS/Linux:** `~/.cursor/extensions/` · **VS Code (ne Cursor):** `~/.vscode/extensions/`
- Pak spusť **Developer: Reload Window**.

### Před upgrade nebo přeinstalací

Pokud už máš starší kopii (včetně publisher **`local`** z rané ruční instalace):

1. Otevři **Extensions**, najdi *Cursor plan usage (status bar)* → **Uninstall** (odstraň **obě** položky `local` i `lukasvladyka`, pokud vidíš dvě).
2. **Úplně zavři Cursor** (File → Exit — všechna okna). *Developer: Reload Window* nestačí.
3. Pokud instalace pořád selže, vyčisti ghost záznamy v registru — viz troubleshooting níže.
4. Nainstaluj VSIX (Možnost A).

> **VSIX soubor vs složka na disku:** stahuješ `cursor-usage-status-*.vsix`, ale Cursor instaluje do `{publisher}.{název}-{verze}` z `package.json` — ne podle názvu `.vsix`.

### Instalace — řešení problémů

**Chyba: *„Please restart VS Code before reinstalling Cursor plan usage (status bar).“***

Samotný restart Cursoru **tento stav neopraví**. Cursor si v registru rozšíření (`extensions.json`) pamatuje **ghost záznamy**, zatímco složka na disku chybí — typické po ručním smazání složky, přerušené VSIX instalaci nebo migraci z `local.*` na `lukasvladyka.*`.

**Oprava (Cursor úplně zavřený):**

1. **Preferováno — CLI uninstall** (pokud máš `cursor` v PATH):

   ```powershell
   cursor --uninstall-extension local.cursor-usage-status
   cursor --uninstall-extension lukasvladyka.cursor-usage-status
   ```

2. **Záloha — reset skript** z tohoto repa (spouštěj jen z oficiálního klonu):

   ```powershell
   cd cesta\k\cursor-usage
   .\reset-cursor-usage-extension.ps1 -WhatIf    # náhled
   .\reset-cursor-usage-extension.ps1            # vyžádá potvrzení
   ```

3. **Poslední možnost — ruční editace JSON:** zálohuj `%USERPROFILE%\.cursor\extensions\extensions.json`, odstraň záznamy s `identifier.id` `local.cursor-usage-status` nebo `lukasvladyka.cursor-usage-status`. **Nikdy needituj za běhu Cursoru.**

4. Znovu otevři Cursor → **Extensions: Install from VSIX...** → vyber `.vsix` → **Developer: Reload Window**.

**Nikdy nemaž ručně složky** z `.cursor\extensions\` — vždy použij **Uninstall** v panelu Extensions.

### Nastavení session tokenu (Command Palette) — typický první krok

1. V prohlížeči se přihlas na [cursor.com](https://cursor.com), otevři DevTools → **Application** → **Cookies** → doména cursor.com → zkopíruj hodnotu cookie **`WorkosCursorSessionToken`** (dlouhý řetězec, chovej se k němu jako k heslu).
2. V Cursoru stiskni **Ctrl+Shift+P** (Command Palette).
3. Napiš **`Cursor usage: Set session token`** a vyber příkaz **„Cursor usage: Set session token…“**.
4. Objeví se **úzké pole nahoře** (maskované jako heslo). **Vlož jen hodnotu cookie** a potvrď Enterem.

> **Častá chyba:** místo pole se zobrazí **seznam souborů z projektu** (např. `cursor-usage.ps1`). To znamená, že jsi otevřel rychlé otevírání souborů, ne příkaz — zavři to, znovu **Ctrl+Shift+P** a vyber příkaz přímo z palety.

**Alternativy nastavení tokenu**

- **User Settings:** najdi `cursorUsageStatus.sessionToken` a vlož hodnotu (User scope — nikdy workspace).
- **Proměnná prostředí:** `CURSOR_SESSION_TOKEN` nastavit před spuštěním Cursoru.

Po nastavení tokenu uvidíš ve status baru např. `Total 6% · Auto 4% · API 13%`. Kliknutím obnovíš ručně; po najetí myší se zobrazí detail (konec billing cyklu + odkaz na dashboard).

### Nastavení rozšíření

| Klíč | Výchozí | Význam |
|------|---------|--------|
| `cursorUsageStatus.sessionToken` | prázdné | Hodnota session cookie (User settings). |
| `cursorUsageStatus.refreshIntervalMinutes` | `5` | Interval obnovení v minutách (1–120). |

### Příkazy (Command Palette)

| Příkaz | Účel |
|--------|------|
| `Cursor usage: Refresh now` | Okamžité obnovení (stejné jako klik na položku ve status baru). |
| `Cursor usage: Set session token…` | Bezpečné vložení tokenu (maskovaný input). |
| `Cursor usage: Open dashboard` | Otevře [cursor.com/dashboard/usage](https://cursor.com/dashboard/usage). |

---

## PowerShell skript

Stejné API. Token bere v tomto pořadí:

1. parametr `-SessionToken`  
2. proměnná prostředí **`CURSOR_SESSION_TOKEN`** (process scope)  
3. soubor **`%USERPROFILE%\.cursor-usage\config.json`** s `{ "session_token": "..." }`

```powershell
cd cesta\k\Cursor_usage
.\cursor-usage.ps1                                  # jeden výpis
.\cursor-usage.ps1 -Watch                           # každých 5 min
.\cursor-usage.ps1 -Watch -IntervalSeconds 600 -NotifyAtPercent 0
```

Skript a rozšíření **nesdílí** úložiště tokenu — skript čte env / `.cursor-usage/config.json`, rozšíření čte VS Code settings. Stejná hodnota cookie, dvě různá místa.

Citlivé soubory zůstávají v `.gitignore` (`.cursor-usage/`, `*.local.json`, `.env*`).

---

## Získání `WorkosCursorSessionToken` z prohlížeče

1. Přihlas se na https://cursor.com v **Chrome / Edge / Firefox**.  
2. **F12** → **Application** (Aplikace) nebo **Storage** (Úložiště) → **Cookies** → `https://cursor.com`.  
3. Najdi řádek **`WorkosCursorSessionToken`** → zkopíruj **Value**.

Hodnotu **nikdy nevkládej** do issues, chatu ani commitu.

---

## Omezení & poznámky

- Billing je **měsíční**, dva pooly (Auto + Composer vs API). Z tohoto API **nedostaneš** denní/týdenní slidery jako u Claude Code.
- Při **HTTP 401/403** se rozšíření zbarví červeně — obnov si cookie v prohlížeči a znovu ulož přes *Set session token*.
- Endpoint je neoficiální; když Cursor změní strukturu odpovědi, bude potřeba parser upravit.

---

## Autor

**Lukáš Vladyka**  
- Email: [vladykosss@gmail.com](mailto:vladykosss@gmail.com)  
- LinkedIn: [linkedin.com/in/lukáš-vladyka](https://www.linkedin.com/in/luk%C3%A1%C5%A1-vladyka/)

## Licence

[MIT](./LICENSE)
