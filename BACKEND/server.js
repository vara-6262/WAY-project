// ============================================================
// Sabus hub server — Node.js, zero dipendenze (solo built-in).
// Fa da ponte tra desktop e telefono: conserva lo stato condiviso
// (calendario + stato del giorno) e lo fonde in modo atomico.
//
// Avvio:
//   SABUS_TOKEN="una-stringa-segreta" node server.js
// Opzionali (env):
//   PORT       (default 8787)
//   DATA_DIR   (default ./data)   cartella dei file JSON
//
// Autenticazione: header  Authorization: Bearer <SABUS_TOKEN>  su tutte
// le rotte tranne /health. CORS abilitato per l'uso da app/browser.
// ============================================================

'use strict';
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');

const PORT = Number(process.env.PORT || 8787);
const TOKEN = process.env.SABUS_TOKEN || '';
const DATA_DIR = process.env.DATA_DIR || path.join(__dirname, 'data');
const MAX_BODY = 5 * 1024 * 1024; // 5 MB

if (!TOKEN) {
  console.error('ERRORE: imposta SABUS_TOKEN (es. SABUS_TOKEN="segreto" node server.js)');
  process.exit(1);
}
fs.mkdirSync(DATA_DIR, { recursive: true });

// ---------- storage su file con versione + scritture serializzate ----------
const cache = new Map();          // name -> { version, updatedAt, data }
const locks = new Map();          // name -> Promise (coda di scrittura per doc)

function docPath(name) { return path.join(DATA_DIR, `${name}.json`); }

function loadDoc(name) {
  if (cache.has(name)) return cache.get(name);
  try {
    const raw = fs.readFileSync(docPath(name), 'utf8');
    const doc = JSON.parse(raw);
    cache.set(name, doc);
    return doc;
  } catch (_) {
    const empty = { version: 0, updatedAt: null, data: null };
    cache.set(name, empty);
    return empty;
  }
}

function persist(name, doc) {
  // scrittura atomica: file temporaneo + rename
  const tmp = docPath(name) + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(doc, null, 2));
  fs.renameSync(tmp, docPath(name));
  cache.set(name, doc);
}

// esegue fn() in mutua esclusione per quel doc (evita race sulle scritture)
function withLock(name, fn) {
  const prev = locks.get(name) || Promise.resolve();
  const next = prev.then(fn, fn);
  locks.set(name, next.catch(() => {}));
  return next;
}

// ---------- merge dello stato del giorno (LWW per-campo) ----------
function normalizeToday(t) {
  return {
    date: t && t.date ? String(t.date) : '',
    completions: (t && t.completions) || {},
    flessioni: (t && typeof t.flessioni === 'number') ? t.flessioni : 0,
    flexTs: (t && typeof t.flexTs === 'number') ? t.flexTs : 0,
  };
}

function mergeToday(stored, incoming) {
  const a = normalizeToday(stored);
  const b = normalizeToday(incoming);
  if (!stored || !stored.date) return b;
  if (!incoming) return a;
  // giorno diverso: vince la data più recente (senza fondere i completamenti)
  if (a.date && b.date && a.date !== b.date) return b.date > a.date ? b : a;

  const completions = Object.assign({}, a.completions);
  for (const id of Object.keys(b.completions)) {
    const x = completions[id];
    const y = b.completions[id];
    if (!x) { completions[id] = y; continue; }
    const yWins = (y.ts > x.ts) || (y.ts === x.ts && String(y.dev) > String(x.dev));
    completions[id] = yWins ? y : x;
  }
  // flessioni: LWW sul timestamp (per la versione robusta vedi nota nel README: registro di delta)
  let flessioni = a.flessioni, flexTs = a.flexTs;
  if (b.flexTs > flexTs) { flessioni = b.flessioni; flexTs = b.flexTs; }

  return { date: a.date || b.date, completions, flessioni, flexTs };
}

// ---------- helper HTTP ----------
function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Authorization, Content-Type, If-Match');
  res.setHeader('Access-Control-Expose-Headers', 'ETag');
}
function sendJson(res, status, obj, extraHeaders) {
  cors(res);
  if (extraHeaders) for (const [k, v] of Object.entries(extraHeaders)) res.setHeader(k, v);
  res.setHeader('Content-Type', 'application/json; charset=utf-8');
  res.writeHead(status);
  res.end(JSON.stringify(obj));
}
function authed(req) {
  const h = req.headers['authorization'] || '';
  return h === `Bearer ${TOKEN}`;
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    let size = 0; const chunks = [];
    req.on('data', (c) => {
      size += c.length;
      if (size > MAX_BODY) { reject(new Error('body troppo grande')); req.destroy(); return; }
      chunks.push(c);
    });
    req.on('end', () => {
      const s = Buffer.concat(chunks).toString('utf8');
      if (!s) return resolve(null);
      try { resolve(JSON.parse(s)); } catch (e) { reject(new Error('JSON non valido')); }
    });
    req.on('error', reject);
  });
}

// ---------- routing ----------
const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://localhost:${PORT}`);
  const p = url.pathname;
  const method = req.method;

  if (method === 'OPTIONS') { cors(res); res.writeHead(204); return res.end(); }
  if (p === '/health') return sendJson(res, 200, { ok: true, service: 'sabus-hub' });

  if (!authed(req)) return sendJson(res, 401, { error: 'non autorizzato' });

  try {
    // --- GET di un documento versionato ---  /calendar  /today  /doc/<name>
    const getName = matchGet(p);
    if (method === 'GET' && getName) {
      const doc = loadDoc(getName);
      return sendJson(res, 200, { version: doc.version, updatedAt: doc.updatedAt, data: doc.data },
        { ETag: String(doc.version) });
    }

    // --- POST /today/merge : merge atomico dei completamenti ---
    if (method === 'POST' && p === '/today/merge') {
      const incoming = await readBody(req);
      const result = await withLock('today', () => {
        const doc = loadDoc('today');
        const merged = mergeToday(doc.data, incoming);
        const next = { version: doc.version + 1, updatedAt: new Date().toISOString(), data: merged };
        persist('today', next);
        return next;
      });
      return sendJson(res, 200, { version: result.version, updatedAt: result.updatedAt, data: result.data },
        { ETag: String(result.version) });
    }

    // --- PUT di un documento versionato (concorrenza ottimistica con If-Match) ---
    const putName = matchPut(p);
    if (method === 'PUT' && putName) {
      const body = await readBody(req);
      const result = await withLock(putName, () => {
        const doc = loadDoc(putName);
        const ifMatch = req.headers['if-match'];
        if (ifMatch !== undefined && String(ifMatch) !== String(doc.version)) {
          return { conflict: true, current: doc.version };
        }
        const next = { version: doc.version + 1, updatedAt: new Date().toISOString(), data: body };
        persist(putName, next);
        return next;
      });
      if (result.conflict) {
        return sendJson(res, 409, { error: 'conflitto di versione', current: result.current },
          { ETag: String(result.current) });
      }
      return sendJson(res, 200, { version: result.version, updatedAt: result.updatedAt },
        { ETag: String(result.version) });
    }

    return sendJson(res, 404, { error: 'rotta non trovata' });
  } catch (e) {
    return sendJson(res, 400, { error: String(e.message || e) });
  }
});

// nomi documento consentiti
function safeName(n) { return /^[a-z0-9_-]{1,40}$/i.test(n) ? n : null; }
function matchGet(p) {
  if (p === '/calendar') return 'calendar';
  if (p === '/today') return 'today';
  if (p.startsWith('/doc/')) return safeName(p.slice(5));
  return null;
}
function matchPut(p) {
  if (p === '/calendar') return 'calendar';
  if (p === '/today') return 'today';
  if (p.startsWith('/doc/')) return safeName(p.slice(5));
  return null;
}

server.listen(PORT, () => {
  console.log(`Sabus hub in ascolto su http://0.0.0.0:${PORT}`);
  console.log(`Dati in: ${DATA_DIR}`);
});
