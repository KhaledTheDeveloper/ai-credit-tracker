const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const test = require('node:test');

const {
  decodeJwtPayload,
  persistRefreshedAccessToken
} = require('./index.js');

function withTokenFile(contents, run) {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'quotabar-engine-tests-'));
  const tokenPath = path.join(directory, 'tokens.json');
  fs.writeFileSync(tokenPath, JSON.stringify(contents));
  try {
    run(tokenPath);
  } finally {
    fs.rmSync(directory, { recursive: true, force: true });
  }
}

test('decodes a JWT payload', () => {
  const payload = Buffer.from(JSON.stringify({ email: 'user@example.com' }))
    .toString('base64url');
  assert.deepEqual(
    decodeJwtPayload(`header.${payload}.signature`),
    { email: 'user@example.com' }
  );
});

test('persists refreshed tokens in nested Antigravity format', () => {
  withTokenFile({ token: { access_token: 'old' }, email: 'user@example.com' }, tokenPath => {
    persistRefreshedAccessToken(
      { email: 'user@example.com', tokenPath },
      'fresh'
    );
    const stored = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
    assert.equal(stored.token.access_token, 'fresh');
    assert.equal(stored.token.accessToken, 'fresh');
  });
});

test('persists refreshed tokens in refresh-token-only account files', () => {
  withTokenFile({ email: 'user@example.com', refreshToken: 'refresh' }, tokenPath => {
    persistRefreshedAccessToken(
      { email: 'user@example.com', tokenPath },
      'fresh'
    );
    const stored = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
    assert.equal(stored.accessToken, 'fresh');
    assert.equal(stored.access_token, 'fresh');
    assert.ok(stored.expiresAt > Date.now());
  });
});

test('persists refreshed tokens in flat multi-account files', () => {
  withTokenFile({ 'user@example.com': { refresh_token: 'refresh' } }, tokenPath => {
    persistRefreshedAccessToken(
      { email: 'user@example.com', tokenPath },
      'fresh'
    );
    const stored = JSON.parse(fs.readFileSync(tokenPath, 'utf8'));
    assert.equal(stored['user@example.com'].accessToken, 'fresh');
    assert.equal(stored['user@example.com'].access_token, 'fresh');
  });
});
