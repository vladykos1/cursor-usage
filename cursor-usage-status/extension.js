'use strict';

const vscode = require('vscode');
const https = require('https');

const EXTENSION_VERSION = '0.1.1';

/** @type {vscode.StatusBarItem | undefined} */
let statusItem;
/** @type {ReturnType<typeof setInterval> | undefined} */
let intervalId;

/**
 * @param {string} token
 * @returns {Promise<Record<string, unknown>>}
 */
function fetchUsageSummary(token) {
  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'cursor.com',
        port: 443,
        path: '/api/usage-summary',
        method: 'GET',
        headers: {
          Cookie: `WorkosCursorSessionToken=${token}`,
          'User-Agent': `cursor-usage-status/${EXTENSION_VERSION}`,
        },
      },
      (res) => {
        const chunks = [];
        res.on('data', (c) => chunks.push(c));
        res.on('end', () => {
          const buf = Buffer.concat(chunks).toString('utf8');
          if (res.statusCode !== 200) {
            reject(new Error(`HTTP ${res.statusCode}: ${buf.slice(0, 200)}`));
            return;
          }
          try {
            resolve(JSON.parse(buf));
          } catch (e) {
            reject(e);
          }
        });
      }
    );
    req.on('error', reject);
    req.setTimeout(25000, () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });
    req.end();
  });
}

/**
 * @param {Record<string, unknown>} data
 */
function parsePlanPercents(data) {
  const ind = /** @type {Record<string, unknown> | undefined} */ (data.individualUsage);
  const plan = /** @type {Record<string, unknown> | undefined} */ (ind && ind.plan);
  const auto = Number((plan && plan.autoPercentUsed) ?? 0);
  const api = Number((plan && plan.apiPercentUsed) ?? 0);
  const total = Number((plan && plan.totalPercentUsed) ?? 0);
  return { auto, api, total };
}

function getToken() {
  const env = process.env.CURSOR_SESSION_TOKEN;
  if (env && String(env).trim()) {
    return String(env).trim();
  }
  const cfg = vscode.workspace.getConfiguration('cursorUsageStatus');
  return String(cfg.get('sessionToken') || '').trim();
}

function clearRefreshInterval() {
  if (intervalId !== undefined) {
    clearInterval(intervalId);
    intervalId = undefined;
  }
}

function startRefreshInterval(refresh) {
  clearRefreshInterval();
  const cfg = vscode.workspace.getConfiguration('cursorUsageStatus');
  const minutes = Math.max(1, Number(cfg.get('refreshIntervalMinutes')) || 5);
  intervalId = setInterval(refresh, minutes * 60 * 1000);
}

/**
 * @param {vscode.ExtensionContext} context
 */
async function refresh(context) {
  if (!statusItem) {
    return;
  }
  const token = getToken();
  if (!token) {
    statusItem.text = '$(key) Cursor usage: set token';
    const tipMissing = new vscode.MarkdownString(
      '**No session token**\n\n' +
        '- Command palette: **Cursor usage: Set session token…**\n' +
        '- Or set User setting `cursorUsageStatus.sessionToken`\n' +
        '- Or set env `CURSOR_SESSION_TOKEN` when starting Cursor'
    );
    tipMissing.isTrusted = true;
    statusItem.tooltip = tipMissing;
    statusItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
    statusItem.show();
    return;
  }

  try {
    const data = await fetchUsageSummary(token);
    const { auto, api, total } = parsePlanPercents(data);
    const end = /** @type {string} */ (data.billingCycleEnd || '');
    const membership = /** @type {string} */ (data.membershipType || '');

    statusItem.text = `$(pulse) Total ${total.toFixed(0)}% · Auto ${auto.toFixed(0)}% · API ${api.toFixed(0)}%`;
    const md = new vscode.MarkdownString(
      `**Cursor plan usage** (pools reset with billing)\n\n` +
        `- **Total (Included in Pro): ${total.toFixed(1)}%**\n` +
        `- Auto + Composer: ${auto.toFixed(1)}%\n` +
        `- API (named models): ${api.toFixed(1)}%\n\n` +
        `_ ${membership.replace(/_/g, ' ')} · cycle end: ${end}_\n\n` +
        `[Open usage dashboard](https://cursor.com/dashboard/usage)`
    );
    md.isTrusted = true;
    statusItem.tooltip = md;
    statusItem.backgroundColor = undefined;
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    statusItem.text = '$(error) Cursor usage';
    statusItem.tooltip = `Refresh failed: ${msg}\n\nClick to retry. Check token (401) or network.`;
    statusItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
  }
  statusItem.show();
}

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {
  // High priority = further left within the right status bar group (usually stays visible).
  statusItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Right, 10_000);
  statusItem.name = 'Cursor plan usage';
  statusItem.command = 'cursorUsageStatus.refresh';

  const doRefresh = () => refresh(context);

  context.subscriptions.push(
    statusItem,
    vscode.commands.registerCommand('cursorUsageStatus.refresh', doRefresh),
    vscode.commands.registerCommand('cursorUsageStatus.setToken', async () => {
      const value = await vscode.window.showInputBox({
        title: 'WorkosCursorSessionToken',
        prompt: 'Paste cookie value from cursor.com (same as browser session).',
        password: true,
        ignoreFocusOut: true,
      });
      if (value !== undefined && value.trim()) {
        await vscode.workspace
          .getConfiguration('cursorUsageStatus')
          .update('sessionToken', value.trim(), vscode.ConfigurationTarget.Global);
        await doRefresh();
      }
    }),
    vscode.commands.registerCommand('cursorUsageStatus.openUsageDashboard', () => {
      vscode.env.openExternal(vscode.Uri.parse('https://cursor.com/dashboard/usage'));
    }),
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration('cursorUsageStatus')) {
        startRefreshInterval(doRefresh);
        void doRefresh();
      }
    }),
    { dispose: () => clearRefreshInterval() }
  );

  startRefreshInterval(doRefresh);
  void doRefresh();
}

function deactivate() {
  clearRefreshInterval();
  statusItem = undefined;
}

module.exports = { activate, deactivate };
