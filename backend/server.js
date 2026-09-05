const express = require('express');

const app = express();
app.disable('x-powered-by');

const SUPABASE_URL = 'https://gftlkxpzympplwluxmah.supabase.co';
const SUPABASE_KEY = 'sb_publishable_ZzcG37T_pgUGeAt_J6gr3w_ocfDTb9I';
const USER_AGENT = 'Mozilla/5.0 (Linux; Android 15) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0 Mobile Safari/537.36';

function mediaFireUrl(value) {
  if (!value) return null;
  try {
    const url = new URL(value);
    if (!['mediafire.com', 'www.mediafire.com', 'mfi.re'].includes(url.hostname)) return null;
    return url.toString();
  } catch (_) { return null; }
}

function decodeHtml(value) {
  return value.replace(/\\\//g, '/').replace(/\\u002F/gi, '/').replace(/\\u0026/gi, '&')
    .replace(/&amp;/gi, '&').replace(/&quot;/gi, '"').replace(/&#x2F;/gi, '/').replace(/&#47;/gi, '/');
}

function resolveUrl(value, base) {
  if (!value) return null;
  const candidate = decodeHtml(value).trim();
  if (!candidate || candidate.startsWith('#') || /^javascript:/i.test(candidate)) return null;
  try { return new URL(candidate, base).toString(); } catch (_) { return null; }
}

function extractDirect(html, base) {
  const text = decodeHtml(html);
  const patterns = [
    /href\s*=\s*["'](https?:\/\/download\d+\.mediafire\.com\/[^"']+)["']/i,
    /(?:download_url|downloadLink|downloadUrl)\s*[:=]\s*["']([^"']+)["']/i,
    /data-download-url\s*=\s*["']([^"']+)["']/i,
    /(["'])((?:https?:)?\/\/download\d+\.mediafire\.com\/[^"'\s<>]+)\1/i,
  ];
  for (const pattern of patterns) {
    const match = pattern.exec(text);
    if (!match) continue;
    const value = match[2] || match[1];
    const url = resolveUrl(value, base);
    if (url && /^https?:\/\/download\d+\.mediafire\.com\//i.test(url)) return url;
  }
  return null;
}

function extractContinue(html, base) {
  const text = decodeHtml(html);
  const patterns = [
    /<a[^>]+id\s*=\s*["']continue-btn["'][^>]+href\s*=\s*["']([^"']+)["']/i,
    /<a[^>]+href\s*=\s*["']([^"']+)["'][^>]+id\s*=\s*["']continue-btn["']/i,
    /id\s*=\s*["']continue-btn["'][^>]*href\s*=\s*["']([^"']+)["']/i,
  ];
  for (const pattern of patterns) {
    const match = pattern.exec(text);
    if (match) return resolveUrl(match[1], base);
  }
  return null;
}

function extractDkeyUrl(html, base) {
  const text = decodeHtml(html);
  const patterns = [
    /(?:https?:)?\/\/www\.mediafire\.com\/file\/[^"'\s<>?]+\?dkey=[^"'\s<>]+/i,
    /(?:https?:)?\/\/mediafire\.com\/file\/[^"'\s<>?]+\?dkey=[^"'\s<>]+/i,
    /(?:https?:)?\/\/www\.mediafire\.com\/(?:file|download|view)\/[^"'\s<>?]+\?dkey=[^"'\s<>]+/i,
  ];
  for (const pattern of patterns) {
    const match = pattern.exec(text);
    if (match) return resolveUrl(match[0], base);
  }
  return null;
}

function parseFileName(value) {
  if (!value) return null;
  const utf = /filename\*=UTF-8''([^;]+)/i.exec(value);
  if (utf) { try { return decodeURIComponent(utf[1].replace(/^"|"$/g, '')); } catch (_) {} }
  const normal = /filename\s*=\s*"?([^";]+)"?/i.exec(value);
  return normal ? normal[1].trim() : null;
}

async function fetchPage(url, cookie = '') {
  const headers = {
    'User-Agent': USER_AGENT,
    Accept: 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'ar-DZ,ar;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control': 'no-cache',
  };
  if (cookie) headers.Cookie = cookie;
  const response = await fetch(url, { headers, redirect: 'follow' });
  const setCookie = response.headers.get('set-cookie');
  const body = await response.text();
  const nextCookie = setCookie ? setCookie.split(/,(?=[^;]+?=)/).map(x => x.split(';')[0]).join('; ') : cookie;
  return { response, body, cookie: nextCookie };
}

async function resolveMediaFire(url) {
  let current = mediaFireUrl(url);
  if (!current) throw new Error('INVALID_MEDIAFIRE_URL');
  let cookie = '';
  for (let attempt = 0; attempt < 6; attempt++) {
    const page = await fetchPage(current, cookie);
    cookie = page.cookie || cookie;
    const base = new URL(page.response.url || current);
    const direct = extractDirect(page.body, base);
    if (direct) return { url: direct, cookie };
    const dkey = extractDkeyUrl(page.body, base);
    if (dkey && dkey !== current) { current = dkey; continue; }
    const next = extractContinue(page.body, base);
    if (next && next !== current) { await new Promise(r => setTimeout(r, 1500)); current = next; continue; }
    const lower = page.body.toLowerCase();
    if (lower.includes('captcha') || lower.includes('cloudflare')) throw new Error('MEDIAFIRE_VERIFICATION_REQUIRED');
    if (lower.includes('generating new download key')) throw new Error('MEDIAFIRE_DOWNLOAD_KEY_PENDING');
    throw new Error('DIRECT_LINK_NOT_FOUND');
  }
  throw new Error('MEDIAFIRE_RESOLUTION_TIMEOUT');
}

async function querySupabase(path) {
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    headers: { apikey: SUPABASE_KEY, Authorization: `Bearer ${SUPABASE_KEY}` },
  });
  if (!response.ok) return { ok: false, rows: [] };
  const rows = await response.json();
  return { ok: true, rows: Array.isArray(rows) ? rows : [] };
}

async function getBook(bookId) {
  if (!bookId || !/^[a-zA-Z0-9_-]+$/.test(bookId)) throw new Error('INVALID_BOOK_ID');

  // Regular books.
  const books = await querySupabase(`books?id=eq.${encodeURIComponent(bookId)}&select=download_url,title`);
  if (books.ok && books.rows.length) {
    const url = mediaFireUrl(books.rows[0].download_url);
    if (!url) throw new Error('INVALID_MEDIAFIRE_URL');
    return { url, title: books.rows[0].title || 'kitara_file' };
  }

  // Magazine issues use a separate table and must follow the exact same
  // download pipeline as regular books.
  const issues = await querySupabase(
    `magazine_issues?id=eq.${encodeURIComponent(bookId)}&select=download_url,title,issue_number`,
  );
  if (issues.ok && issues.rows.length) {
    const row = issues.rows[0];
    const url = mediaFireUrl(row.download_url);
    if (!url) throw new Error('INVALID_MEDIAFIRE_URL');
    finalTitle = row.title || `مجلة - العدد ${row.issue_number ?? ''}`;
    return { url, title: finalTitle.trim() || 'kitara_magazine' };
  }

  if (!books.ok && !issues.ok) throw new Error('DATABASE_ERROR');
  throw new Error('BOOK_NOT_FOUND');
}

function sendError(res, error) {
  const code = error?.message || 'PROXY_ERROR';
  const messages = {
    INVALID_BOOK_ID: 'معرّف الكتاب غير صالح.', BOOK_NOT_FOUND: 'الكتاب غير موجود.',
    INVALID_MEDIAFIRE_URL: 'رابط MediaFire غير صالح.', DATABASE_ERROR: 'تعذر الوصول إلى بيانات المحتوى.',
    DIRECT_LINK_NOT_FOUND: 'تعذر العثور على الملف الحقيقي في MediaFire.',
    MEDIAFIRE_DOWNLOAD_KEY_PENDING: 'MediaFire لم يجهز رابط التنزيل بعد.',
    MEDIAFIRE_VERIFICATION_REQUIRED: 'MediaFire طلب التحقق قبل التنزيل.',
    MEDIAFIRE_RESOLUTION_TIMEOUT: 'انتهت مهلة استخراج رابط الملف.',
    INVALID_UPSTREAM_RESPONSE: 'الخادم أعاد صفحة غير صالحة بدل الملف.',
    EMPTY_UPSTREAM_BODY: 'الملف فارغ.',
  };
  res.status(502).json({ success: false, code, error: messages[code] || 'تعذر تنزيل الملف.' });
}

app.get('/', (_req, res) => res.json({ ok: true, service: 'KITARA download proxy' }));

app.get('/download/:bookId', async (req, res) => {
  try {
    const book = await getBook(req.params.bookId);
    const resolved = await resolveMediaFire(book.url);
    const upstream = await fetch(resolved.url, {
      headers: { 'User-Agent': USER_AGENT, Accept: '*/*', Referer: book.url, ...(resolved.cookie ? { Cookie: resolved.cookie } : {}) },
      redirect: 'follow',
    });
    if (!upstream.ok) throw new Error(`UPSTREAM_HTTP_${upstream.status}`);
    const type = upstream.headers.get('content-type') || 'application/octet-stream';
    if (/text\/html|application\/json/i.test(type)) throw new Error('INVALID_UPSTREAM_RESPONSE');
    res.setHeader('Content-Type', type);
    const length = upstream.headers.get('content-length');
    if (length) res.setHeader('Content-Length', length);
    const fileName = parseFileName(upstream.headers.get('content-disposition')) || book.title;
    res.setHeader('Content-Disposition', `attachment; filename="${fileName.replace(/[\\/:*?"<>|]/g, '_')}"`);
    if (!upstream.body) throw new Error('EMPTY_UPSTREAM_BODY');
    const { Readable } = require('stream');
    Readable.fromWeb(upstream.body).pipe(res);
  } catch (error) {
    console.error('KITARA proxy error:', error.message);
    if (!res.headersSent) sendError(res, error); else res.end();
  }
});

app.get('/info/:bookId', async (req, res) => {
  try {
    const book = await getBook(req.params.bookId);
    const resolved = await resolveMediaFire(book.url);
    const response = await fetch(resolved.url, { method: 'HEAD', headers: { 'User-Agent': USER_AGENT } });
    res.json({ success: response.ok, type: response.headers.get('content-type'), size: response.headers.get('content-length') });
  } catch (error) { sendError(res, error); }
});

module.exports = app;
if (!process.env.VERCEL) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`KITARA proxy listening on ${PORT}`));
}
