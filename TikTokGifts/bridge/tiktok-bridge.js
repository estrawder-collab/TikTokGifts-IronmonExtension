#!/usr/bin/env node
/*
  TikTok LIVE -> Ironmon Tracker bridge

  Receives your TikTok LIVE gifts and appends each one to ../gifts.txt as:
      user<TAB>giftName<TAB>coinsEach<TAB>count
  The TikTokGifts.lua extension reads that file inside BizHawk.

  Usage:
    node tiktok-bridge.js
        Default. Gets gifts from the TikFinity Desktop app (free) through its
        local event feed at ws://localhost:21213. No npm install needed.
    node tiktok-bridge.js --direct <your_tiktok_username>
        Connects to TikTok itself with tiktok-live-connector. Needs "npm install"
        and, currently, a paid Euler Stream plan with an API key in apikey.txt.
    node tiktok-bridge.js --test "Hat and Mustache" 30 1
        Writes a fake gift (no TikTok needed).
*/
const fs = require('fs');
const path = require('path');

const GIFTS_FILE = process.env.GIFTS_FILE || path.join(__dirname, '..', 'gifts.txt');
const TIKFINITY_URL = process.env.TIKFINITY_URL || 'ws://localhost:21213/';
const RECONNECT_SECONDS = 5;

const clean = (s) => String(s ?? '').replace(/[\t\r\n]/g, ' ').trim();

function writeGift(user, giftName, coins, count) {
  const line = [clean(user) || 'someone', clean(giftName) || 'Unknown', Math.max(0, coins | 0), Math.max(1, count | 0)].join('\t') + '\n';
  fs.appendFileSync(GIFTS_FILE, line, 'utf8');
  console.log(`[gift] ${user} sent ${count}x ${giftName} (${coins} coins each)`);
}

// Gift events use the same field names in TikFinity and tiktok-live-connector;
// nested variants are handled too.
const seenMsgIds = [];
const truthy = (v) => v === true || v === 1 || v === '1' || String(v).toLowerCase() === 'true';
function onGift(d) {
  if (!d) return;
  const details = d.giftDetails || d.gift || {};
  const extra = d.extendedGiftInfo || {};
  const giftType = Number(d.giftType ?? details.giftType ?? details.gift_type ?? details.type);
  const repeatEnd = d.repeatEnd ?? details.repeatEnd ?? details.repeat_end;
  // Streakable gifts (type 1) fire repeatedly; only count them when the streak ends
  if (giftType === 1 && !truthy(repeatEnd)) {
    console.log(`[tikfinity] ${d.giftName ?? details.giftName ?? details.name ?? 'gift'} streak in progress (x${d.repeatCount ?? '?'}), waiting for it to end...`);
    return;
  }

  // Ignore the same message arriving twice
  const msgId = d.msgId ?? d.common?.msgId;
  if (msgId != null) {
    if (seenMsgIds.includes(String(msgId))) return;
    seenMsgIds.push(String(msgId));
    if (seenMsgIds.length > 500) seenMsgIds.shift();
  }

  const giftName = d.giftName ?? details.giftName ?? extra.name ?? details.name ?? `gift#${d.giftId}`;
  const coins = d.diamondCount ?? details.diamondCount ?? details.diamond_count ?? extra.diamond_count ?? 0;
  const count = d.repeatCount ?? d.comboCount ?? 1;
  const user = d.uniqueId ?? d.user?.uniqueId ?? d.nickname ?? d.user?.nickname ?? 'someone';
  writeGift(user, giftName, Number(coins), Number(count));
}

const args = process.argv.slice(2);

// ---- Retry mode: ask the extension to retry held gifts now ----
if (args[0] === '--retry') {
  fs.appendFileSync(GIFTS_FILE, '!retry\n', 'utf8');
  console.log('Asked the game to retry held gifts.');
  process.exit(0);
}

// ---- Test mode: write a fake gift and exit ----
if (args[0] === '--test') {
  const [, name = 'Hat and Mustache', coins = '30', count = '1'] = args;
  writeGift('test_viewer', name, Number(coins), Number(count));
  process.exit(0);
}

fs.closeSync(fs.openSync(GIFTS_FILE, 'a'));
console.log(`Gifts will be written to: ${GIFTS_FILE}`);
console.log('This must be inside your Tracker\'s "extensions" folder, or the game won\'t see the gifts.\n');

// Reports what arrives so problems are visible: every gift message is shown,
// and other event types (likes, chat...) are announced the first time they appear.
const seenEventTypes = new Set();
let unreadableShown = 0;
function handleTikFinityMessage(text) {
  let packet;
  try { packet = JSON.parse(text); } catch {
    if (unreadableShown++ < 3) console.log(`[tikfinity] Got a message that isn't JSON: ${text.slice(0, 200)}`);
    return;
  }
  const items = Array.isArray(packet) ? packet : [packet];
  for (const p of items) {
    if (!p || typeof p !== 'object') continue;
    const type = String(p.event ?? p.type ?? p.eventName ?? 'unknown');
    const data = p.data ?? p.payload ?? p;
    if (type.toLowerCase() === 'gift') {
      console.log(`[tikfinity] gift message: ${JSON.stringify(data).slice(0, 300)}`);
      onGift(data);
    } else if (!seenEventTypes.has(type)) {
      seenEventTypes.add(type);
      console.log(`[tikfinity] receiving "${type}" events (TikFinity is sending data)`);
    }
  }
}

// ---- Default mode: TikFinity Desktop's local event feed ----
function startTikFinity() {
  let WS = globalThis.WebSocket; // built into Node.js 22+
  if (!WS) {
    try { WS = require('ws'); } catch {
      console.error('Your Node.js is too old for this. Install the current LTS version from https://nodejs.org');
      process.exit(1);
    }
  }
  let opened = false;
  let ws;
  startTikFinity.failures = startTikFinity.failures || 0;
  try { ws = new WS(TIKFINITY_URL); } catch (e) {
    console.log(`Couldn't open ${TIKFINITY_URL}: ${e.message}. Retrying in ${RECONNECT_SECONDS}s...`);
    setTimeout(startTikFinity, RECONNECT_SECONDS * 1000);
    return;
  }
  ws.onopen = () => {
    opened = true;
    startTikFinity.failures = 0;
    console.log('Connected to TikFinity! Waiting for gifts... (leave this window open)');
  };
  try { ws.binaryType = 'arraybuffer'; } catch {} // binary frames would otherwise arrive as a Blob
  ws.onmessage = async (ev) => {
    let text;
    try {
      const raw = ev.data;
      if (typeof raw === 'string') text = raw;
      else if (raw instanceof ArrayBuffer || ArrayBuffer.isView(raw)) text = Buffer.from(raw.buffer ? raw.buffer : raw).toString('utf8');
      else if (raw && typeof raw.text === 'function') text = await raw.text(); // Blob
      else text = String(raw);
    } catch (e) {
      console.log(`[tikfinity] Couldn't read a message: ${e.message}`);
      return;
    }
    handleTikFinityMessage(text);
  };
  // A refused connection may fire only "error" (Node 22) or "error" + "close",
  // so both lead here, guarded to retry once.
  let retried = false;
  const retry = () => {
    if (retried) return;
    retried = true;
    try { ws.close(); } catch {}
    if (opened) {
      console.log(`Lost connection to TikFinity. Retrying in ${RECONNECT_SECONDS}s...`);
    } else if (startTikFinity.failures++ === 0) {
      // Say it once, not every few seconds (people using only TikOps webhooks won't run TikFinity)
      console.log('TikFinity Desktop isn\'t running (fine if you use TikOps webhooks). Will connect automatically when it opens.');
    }
    setTimeout(startTikFinity, RECONNECT_SECONDS * 1000);
  };
  ws.onerror = retry;
  ws.onclose = retry;
}

// ---- Webhook receiver (for TikOps or any tool that can call a URL) ----
// Accepts GET or POST on http://localhost:21214/gift with any of these fields,
// as URL parameters, JSON or form data:
//   user / username / uniqueId, gift / giftName, coins / diamondCount, count / repeatCount
const WEBHOOK_PORT = Number(process.env.WEBHOOK_PORT || 21214);
function pick(o, keys) {
  for (const k of keys) {
    for (const key of Object.keys(o)) {
      if (key.toLowerCase() === k.toLowerCase() && o[key] !== '' && o[key] != null) return o[key];
    }
  }
  return undefined;
}
function startWebhookServer() {
  const http = require('http');
  const server = http.createServer((req, res) => {
    let body = '';
    req.on('data', (c) => { body += c; if (body.length > 100000) req.destroy(); });
    req.on('end', () => {
      const url = new URL(req.url, 'http://localhost');
      let fields = Object.fromEntries(url.searchParams);
      if (body) {
        let parsed = null;
        try { parsed = JSON.parse(body); } catch {
          parsed = Object.fromEntries(new URLSearchParams(body));
        }
        if (parsed && typeof parsed === 'object') {
          // TikFinity-style {event, data} or a flat object
          if (parsed.data && typeof parsed.data === 'object') {
            if (parsed.event && parsed.event !== 'gift') { res.end('ignored'); return; }
            onGift(parsed.data);
            res.end('ok');
            return;
          }
          fields = { ...fields, ...parsed };
        }
      }
      const giftName = pick(fields, ['gift', 'giftName', 'gift_name', 'name']);
      if (!giftName) {
        console.log(`[webhook] Got a request without a gift name, so it was ignored. It contained: ${JSON.stringify(fields).slice(0, 300)}`);
        res.statusCode = 400;
        res.end('missing gift name');
        return;
      }
      onGift({
        uniqueId: pick(fields, ['user', 'username', 'uniqueId', 'nickname', 'viewer']),
        giftName,
        diamondCount: Number(pick(fields, ['coins', 'diamondCount', 'diamonds', 'value', 'cost']) || 0),
        repeatCount: Number(pick(fields, ['count', 'repeatCount', 'amount', 'quantity']) || 1),
        msgId: pick(fields, ['msgId', 'id', 'eventId']),
      });
      res.end('ok');
    });
  });
  server.on('error', (e) => console.log(`[webhook] Couldn't start the receiver on port ${WEBHOOK_PORT}: ${e.message}`));
  server.listen(WEBHOOK_PORT, '127.0.0.1', () =>
    console.log(`Webhook receiver ready at http://localhost:${WEBHOOK_PORT}/gift (for TikOps)`));
}

// ---- Direct mode: tiktok-live-connector ----
function startDirect(username) {
  let lib;
  try { lib = require('tiktok-live-connector'); } catch {
    console.error('Direct mode needs "npm install" in this folder first.');
    process.exit(1);
  }
  const Connection = lib.TikTokLiveConnection || lib.WebcastPushConnection;
  const GIFT_EVENT = (lib.WebcastEvent && lib.WebcastEvent.GIFT) || 'gift';
  const keyFile = path.join(__dirname, 'apikey.txt');
  const signApiKey = fs.existsSync(keyFile) ? fs.readFileSync(keyFile, 'utf8').trim() : (process.env.TIKTOK_SIGN_API_KEY || '');

  const connect = () => {
    // The options object must be passed: tiktok-live-connector 2.5 reads it unguarded
    const options = { enableExtendedGiftInfo: true };
    if (signApiKey) options.signApiKey = signApiKey;
    const conn = new Connection(username, options);
    conn.on(GIFT_EVENT, onGift);
    let retrying = false;
    const retry = (why) => {
      if (retrying) return;
      retrying = true;
      console.log(`${why} Retrying in 15s...`);
      try { conn.disconnect(); } catch {}
      setTimeout(connect, 15000);
    };
    conn.on('disconnected', () => retry('Disconnected.'));
    conn.on('streamEnd', () => retry('Stream ended.'));
    conn.connect()
      .then((state) => console.log(`Connected to @${username} (room ${state.roomId}).`))
      .catch((err) => retry(`Couldn't connect: ${err && err.message ? err.message : err}.`));
  };
  connect();
}

if (args[0] === '--direct') {
  const username = (args[1] || process.env.TIKTOK_USERNAME || '').replace(/^@/, '');
  if (!username) {
    console.error('Usage: node tiktok-bridge.js --direct <your_tiktok_username>');
    process.exit(1);
  }
  startDirect(username);
} else {
  startWebhookServer();
  startTikFinity();
}
