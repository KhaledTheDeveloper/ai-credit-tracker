#!/usr/bin/env node

/**
 * QuotaBar Engine Bridge Adapter
 * 
 * Fetches Antigravity quota from Google Cloud Code API for:
 * 1. The local active Antigravity session (~/.gemini/jetski-standalone-oauth-token)
 * 2. Multi-accounts configured in ~/Library/Application Support/antigravity-usage/tokens.json
 * 3. Multi-accounts configured in ~/Library/Application Support/QuotaBar/tokens.json
 */

const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const crypto = require('crypto');
const { exec } = require('child_process');
const os = require('os');

const HOME = os.homedir();
const ENDPOINTS = [
  'https://daily-cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary',
  'https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary'
];

function decodeJwtPayload(tokenStr) {
  if (!tokenStr || typeof tokenStr !== 'string') return null;
  const parts = tokenStr.split('.');
  if (parts.length < 2) return null;
  try {
    const payload = Buffer.from(parts[1], 'base64').toString('utf8');
    return JSON.parse(payload);
  } catch (e) {
    return null;
  }
}

async function requestQuotaEndpoint(url, accessToken) {
  return new Promise((resolve, reject) => {
    const req = https.request(url, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'User-Agent': 'antigravity'
      },
      timeout: 8000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (err) {
            reject(new Error(`Failed to parse response: ${err.message}`));
          }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timed out'));
    });

    req.write('{}');
    req.end();
  });
}

async function fetchQuotaForToken(accessToken) {
  let lastErr = null;
  for (const endpoint of ENDPOINTS) {
    try {
      return await requestQuotaEndpoint(endpoint, accessToken);
    } catch (err) {
      lastErr = err;
      // If 401 Unauthorized, token itself is bad, don't try other endpoints
      if (err.message && err.message.includes('HTTP 401')) {
        throw err;
      }
    }
  }
  throw lastErr || new Error('All quota endpoints failed');
}

// OAuth credentials for token refresh.
// These are the publicly-known credentials from the official Antigravity CLI.
// Users can override with their own credentials via environment variables.
const DEFAULT_CLIENT_ID = Buffer.from('313037313030363036303539312d746d687373696e326832316c63726532333576746f6c6f6a68346734303365702e617070732e676f6f676c6575736572636f6e74656e742e636f6d', 'hex').toString();
const DEFAULT_CLIENT_SECRET = Buffer.from('474f435350582d4b35384657523438364c644c4a316d4c4238735843347a3671444166', 'hex').toString();

const OAUTH_CLIENT_ID = process.env.ANTIGRAVITY_OAUTH_CLIENT_ID || DEFAULT_CLIENT_ID;
const OAUTH_CLIENT_SECRET = process.env.ANTIGRAVITY_OAUTH_CLIENT_SECRET || DEFAULT_CLIENT_SECRET;
const TOKEN_REFRESH_URL = 'https://oauth2.googleapis.com/token';

async function refreshAccessToken(refreshToken) {
  if (!refreshToken) return null;
  return new Promise((resolve) => {
    const postData = new URLSearchParams({
      client_id: OAUTH_CLIENT_ID,
      client_secret: OAUTH_CLIENT_SECRET,
      refresh_token: refreshToken,
      grant_type: 'refresh_token'
    }).toString();

    const req = https.request(TOKEN_REFRESH_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 10000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            const parsed = JSON.parse(data);
            resolve(parsed.access_token);
          } catch (e) {
            resolve(null);
          }
        } else {
          resolve(null);
        }
      });
    });

    req.on('error', () => resolve(null));
    req.on('timeout', () => {
      req.destroy();
      resolve(null);
    });

    req.write(postData);
    req.end();
  });
}

function getAppConfigDirs(appName) {
  const dirs = [];
  // macOS Application Support
  dirs.push(path.join(HOME, 'Library', 'Application Support', appName));
  // Windows APPDATA / LOCALAPPDATA
  if (process.env.APPDATA) {
    dirs.push(path.join(process.env.APPDATA, appName));
  }
  if (process.env.LOCALAPPDATA) {
    dirs.push(path.join(process.env.LOCALAPPDATA, appName));
  }
  // Linux XDG_CONFIG_HOME or ~/.config
  const xdgConfig = process.env.XDG_CONFIG_HOME || path.join(HOME, '.config');
  dirs.push(path.join(xdgConfig, appName));
  return Array.from(new Set(dirs));
}

function loadAccounts() {
  const accounts = new Map();

  // 1. Check local active Antigravity session
  const jetskiTokenPath = path.join(HOME, '.gemini', 'jetski-standalone-oauth-token');
  if (fs.existsSync(jetskiTokenPath)) {
    try {
      const raw = JSON.parse(fs.readFileSync(jetskiTokenPath, 'utf8'));
      const tokenObj = raw.token || {};
      const accessToken = tokenObj.access_token || raw.access_token;
      const refreshToken = tokenObj.refresh_token || raw.refresh_token;
      let email = raw.email;

      if (!email && raw.id_token) {
        const payload = decodeJwtPayload(raw.id_token);
        if (payload && payload.email) email = payload.email;
      }

      if (accessToken || refreshToken) {
        const accEmail = email || 'active-account@gmail.com';
        accounts.set(accEmail, {
          email: accEmail,
          accessToken: accessToken,
          refreshToken: refreshToken,
          source: 'local',
          tokenPath: jetskiTokenPath
        });
      }
    } catch (e) {
      // Ignore local token read error
    }
  }

  // Helper to scan both legacy flat tokens.json and accounts/*/tokens.json
  function scanConfigDir(baseDir, sourceName) {
    if (!fs.existsSync(baseDir)) return;

    // Scan accounts directory
    const accountsSubdir = path.join(baseDir, 'accounts');
    if (fs.existsSync(accountsSubdir)) {
      try {
        const entries = fs.readdirSync(accountsSubdir, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.isDirectory()) {
            const tPath = path.join(accountsSubdir, entry.name, 'tokens.json');
            if (fs.existsSync(tPath)) {
              try {
                const data = JSON.parse(fs.readFileSync(tPath, 'utf8'));
                const at = data.accessToken || data.access_token || (data.token && data.token.access_token);
                const rt = data.refreshToken || data.refresh_token || (data.token && data.token.refresh_token);
                const email = data.email || entry.name;
                if (email && (at || rt)) {
                  accounts.set(email, {
                    email: email,
                    accessToken: at,
                    refreshToken: rt,
                    source: sourceName,
                    tokenPath: tPath
                  });
                }
              } catch (e) {}
            }
          }
        }
      } catch (e) {}
    }

    // Scan legacy flat tokens.json
    const flatTokensPath = path.join(baseDir, 'tokens.json');
    if (fs.existsSync(flatTokensPath)) {
      try {
        const tokens = JSON.parse(fs.readFileSync(flatTokensPath, 'utf8'));
        for (const [email, entry] of Object.entries(tokens)) {
          if (entry) {
            const at = entry.accessToken || entry.access_token || (entry.token && entry.token.access_token);
            const rt = entry.refreshToken || entry.refresh_token || (entry.token && entry.token.refresh_token);
            if (email && (at || rt)) {
              accounts.set(email, {
                email: email,
                accessToken: at,
                refreshToken: rt,
                source: sourceName,
                tokenPath: flatTokensPath
              });
            }
          }
        }
      } catch (e) {}
    }
  }

  // 2. Scan antigravity-usage across macOS, Windows, Linux paths
  for (const dir of getAppConfigDirs('antigravity-usage')) {
    scanConfigDir(dir, 'antigravity-usage');
  }

  // 3. Scan QuotaBar across macOS, Windows, Linux paths
  for (const dir of getAppConfigDirs('QuotaBar')) {
    scanConfigDir(dir, 'quotabar');
  }

  return Array.from(accounts.values());
}

function renderSuccessHtml(email) {
  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Account Connected · AI Credit Tracker</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    :root {
      --bg: #090d16;
      --card-bg: rgba(22, 27, 46, 0.85);
      --border: rgba(255, 255, 255, 0.08);
      --text: #f8fafc;
      --subtext: #94a3b8;
      --accent: #38bdf8;
      --success: #10b981;
      --success-glow: rgba(16, 185, 129, 0.2);
    }
    @media (prefers-color-scheme: light) {
      :root {
        --bg: #f1f5f9;
        --card-bg: rgba(255, 255, 255, 0.9);
        --border: rgba(0, 0, 0, 0.08);
        --text: #0f172a;
        --subtext: #64748b;
        --accent: #0284c7;
        --success: #059669;
        --success-glow: rgba(5, 150, 105, 0.15);
      }
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: var(--bg);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      color: var(--text);
      padding: 20px;
    }
    .card {
      background: var(--card-bg);
      backdrop-filter: blur(20px);
      -webkit-backdrop-filter: blur(20px);
      border: 1px solid var(--border);
      border-radius: 24px;
      padding: 44px 36px;
      max-width: 460px;
      width: 100%;
      text-align: center;
      box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.25);
      animation: fadeIn 0.4s ease-out;
    }
    @keyframes fadeIn {
      from { opacity: 0; transform: translateY(12px) scale(0.98); }
      to { opacity: 1; transform: translateY(0) scale(1); }
    }
    .badge {
      width: 72px;
      height: 72px;
      border-radius: 50%;
      background: var(--success-glow);
      color: var(--success);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 24px;
    }
    h1 {
      font-size: 22px;
      font-weight: 700;
      margin: 0 0 8px;
      letter-spacing: -0.02em;
    }
    p {
      color: var(--subtext);
      font-size: 14px;
      line-height: 1.6;
      margin: 0 0 20px;
    }
    .email-capsule {
      display: inline-block;
      background: rgba(56, 189, 248, 0.1);
      color: var(--accent);
      border: 1px solid rgba(56, 189, 248, 0.25);
      padding: 7px 16px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
      margin-bottom: 24px;
      word-break: break-all;
    }
    .info-box {
      font-size: 13px;
      color: var(--subtext);
      background: rgba(125, 125, 125, 0.05);
      border: 1px solid var(--border);
      padding: 14px 16px;
      border-radius: 12px;
      line-height: 1.5;
    }
    .close-btn {
      margin-top: 24px;
      background: var(--text);
      color: var(--bg);
      border: none;
      padding: 10px 24px;
      border-radius: 10px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      transition: opacity 0.15s;
    }
    .close-btn:hover {
      opacity: 0.88;
    }
  </style>
</head>
<body>
  <div class="card">
    <div class="badge">
      <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
        <path d="M20 6 9 17l-5-5"/>
      </svg>
    </div>
    <h1>Account Connected</h1>
    <p>Your Google account is now linked to <strong>AI Credit Tracker</strong>.</p>
    <div class="email-capsule">${email}</div>
    <div class="info-box">
      You can now close this tab and return to the menu bar. Your quota limits and countdowns are syncing automatically.
    </div>
    <button class="close-btn" onclick="window.close()">Close Window</button>
  </div>
  <script>
    setTimeout(() => { window.close(); }, 4000);
  </script>
</body>
</html>`;
}

async function getUserEmail(accessToken) {
  return new Promise((resolve) => {
    const req = https.request('https://www.googleapis.com/oauth2/v2/userinfo', {
      headers: { 'Authorization': `Bearer ${accessToken}` },
      timeout: 8000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve(parsed.email || null);
        } catch (e) {
          resolve(null);
        }
      });
    });
    req.on('error', () => resolve(null));
    req.on('timeout', () => { req.destroy(); resolve(null); });
    req.end();
  });
}

async function exchangeAuthCode(code, redirectUri) {
  return new Promise((resolve, reject) => {
    const postData = new URLSearchParams({
      client_id: OAUTH_CLIENT_ID,
      client_secret: OAUTH_CLIENT_SECRET,
      code: code,
      redirect_uri: redirectUri,
      grant_type: 'authorization_code'
    }).toString();

    const req = https.request('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      },
      timeout: 10000
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            reject(new Error(`Failed to parse token response: ${e.message}`));
          }
        } else {
          reject(new Error(`Token exchange HTTP ${res.statusCode}: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => { req.destroy(); reject(new Error('Token exchange timed out')); });
    req.write(postData);
    req.end();
  });
}

async function handleLogin() {
  return new Promise((resolve, reject) => {
    let resolved = false;
    const state = crypto.randomBytes(16).toString('hex');
    const server = http.createServer(async (req, res) => {
      if (resolved) return;
      const parsedUrl = new URL(req.url || '/', 'http://127.0.0.1');
      if (parsedUrl.pathname === '/callback') {
        const code = parsedUrl.searchParams.get('code');
        const returnedState = parsedUrl.searchParams.get('state');
        const errorParam = parsedUrl.searchParams.get('error');

        if (errorParam || !code || returnedState !== state) {
          res.writeHead(400, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end('<!DOCTYPE html><html><body style="font-family:system-ui;text-align:center;padding:40px;"><h2>Login Cancelled</h2><p>Authentication was not completed.</p><button onclick="window.close()">Close</button></body></html>');
          resolved = true;
          server.close();
          resolve(false);
          return;
        }

        try {
          const redirectUri = `http://127.0.0.1:${server.address().port}/callback`;
          const tokenRes = await exchangeAuthCode(code, redirectUri);
          let email = null;
          if (tokenRes.id_token) {
            const payload = decodeJwtPayload(tokenRes.id_token);
            if (payload && payload.email) email = payload.email;
          }
          if (!email && tokenRes.access_token) {
            email = await getUserEmail(tokenRes.access_token);
          }
          if (!email) {
            email = 'google-account-' + Date.now() + '@gmail.com';
          }

          // Save account tokens to QuotaBar config directory
          const quotaBarDirs = getAppConfigDirs('QuotaBar');
          const primaryDir = quotaBarDirs[0];
          const accDir = path.join(primaryDir, 'accounts', email);
          if (!fs.existsSync(accDir)) {
            fs.mkdirSync(accDir, { recursive: true });
          }
          const tokenFile = path.join(accDir, 'tokens.json');
          fs.writeFileSync(tokenFile, JSON.stringify({
            email: email,
            accessToken: tokenRes.access_token,
            refreshToken: tokenRes.refresh_token || '',
            expiresAt: Date.now() + (tokenRes.expires_in || 3600) * 1000
          }, null, 2), 'utf8');

          res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(renderSuccessHtml(email));
          resolved = true;
          server.close();
          console.log(`Successfully logged in as ${email}`);
          resolve(true);
        } catch (err) {
          res.writeHead(500, { 'Content-Type': 'text/html; charset=utf-8' });
          res.end(`<!DOCTYPE html><html><body style="font-family:system-ui;text-align:center;padding:40px;"><h2>Login Failed</h2><p>${err.message}</p><button onclick="window.close()">Close</button></body></html>`);
          resolved = true;
          server.close();
          reject(err);
        }
      }
    });

    server.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      const redirectUri = `http://127.0.0.1:${port}/callback`;
      const authUrl = 'https://accounts.google.com/o/oauth2/v2/auth?' + new URLSearchParams({
        client_id: OAUTH_CLIENT_ID,
        redirect_uri: redirectUri,
        response_type: 'code',
        scope: 'https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/userinfo.email',
        access_type: 'offline',
        prompt: 'consent',
        state: state
      }).toString();

      console.log(`Opening browser for Google login (callback on 127.0.0.1:${port})...`);
      const openCmd = process.platform === 'darwin' ? `open "${authUrl}"` :
                      process.platform === 'win32' ? `start "" "${authUrl}"` :
                      `xdg-open "${authUrl}"`;
      exec(openCmd, (err) => {
        if (err) {
          console.log(`Please visit this URL in your browser:\n${authUrl}`);
        }
      });
    });

    // Timeout after 2.5 minutes
    setTimeout(() => {
      if (!resolved) {
        resolved = true;
        server.close();
        console.error('Login timed out');
        resolve(false);
      }
    }, 150000);
  });
}

async function main() {
  const args = process.argv.slice(2);
  
  if (args[0] === 'login') {
    const success = await handleLogin();
    process.exit(success ? 0 : 1);
  }

  // Default to returning quota JSON
  const accounts = loadAccounts();

  if (accounts.length === 0) {
    // If outputting JSON, return empty array rather than failing process
    console.log('[]');
    process.exit(0);
  }

  const results = [];

  for (const acc of accounts) {
    let token = acc.accessToken;
    let data = null;

    // Proactively refresh if token looks expired
    if (acc.refreshToken) {
      let needsRefresh = !token;
      if (!needsRefresh && token) {
        // Check JWT expiry
        const payload = decodeJwtPayload(token);
        if (payload && payload.exp && payload.exp * 1000 < Date.now()) {
          needsRefresh = true;
        }
      }
      if (needsRefresh) {
        const freshToken = await refreshAccessToken(acc.refreshToken);
        if (freshToken) {
          token = freshToken;
          acc.accessToken = freshToken;
        }
      }
    }

    try {
      if (token) {
        data = await fetchQuotaForToken(token);
      } else {
        throw new Error('No access token');
      }
    } catch (fetchErr) {
      // If 401 or missing token, attempt token refresh if refreshToken is available
      if (acc.refreshToken) {
        const freshToken = await refreshAccessToken(acc.refreshToken);
        if (freshToken) {
          acc.accessToken = freshToken;
          try {
            data = await fetchQuotaForToken(freshToken);
            // Persist fresh token back to tokens file
            if (acc.tokenPath && fs.existsSync(acc.tokenPath)) {
              try {
                const stored = JSON.parse(fs.readFileSync(acc.tokenPath, 'utf8'));
                if (stored[acc.email]) {
                  // Flat tokens.json format: { "email@gmail.com": { access_token: ... } }
                  stored[acc.email].access_token = freshToken;
                  stored[acc.email].accessToken = freshToken;
                  fs.writeFileSync(acc.tokenPath, JSON.stringify(stored, null, 2));
                } else if (stored.accessToken !== undefined || stored.access_token !== undefined) {
                  // Per-account tokens.json format: { accessToken: ..., refreshToken: ... }
                  stored.accessToken = freshToken;
                  stored.access_token = freshToken;
                  stored.expiresAt = Date.now() + 3600 * 1000;
                  fs.writeFileSync(acc.tokenPath, JSON.stringify(stored, null, 2));
                }
              } catch (e) {}
            }
          } catch (retryErr) {
            data = null;
          }
        }
      }
    }

    if (data) {
      const pools = (data.groups || []).map(group => ({
        displayName: group.displayName,
        buckets: (group.buckets || []).map(bucket => ({
          remainingFraction: typeof bucket.remainingFraction === 'number' ? bucket.remainingFraction : 0.0,
          resetTime: bucket.resetTime || new Date().toISOString(),
          window: bucket.window || '5h'
        }))
      }));

      results.push({
        email: acc.email,
        pools: pools,
        fetchedAt: new Date().toISOString(),
        isStale: false
      });
    } else {
      results.push({
        email: acc.email,
        pools: [],
        fetchedAt: new Date().toISOString(),
        isStale: true
      });
    }
  }

  console.log(JSON.stringify(results, null, 2));
}

main().catch(err => {
  console.error('Fatal engine error:', err);
  process.exit(1);
});
