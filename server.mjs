import http from 'node:http';
import { readFile } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { spawn } from 'node:child_process';
import { promisify } from 'node:util';
import { writeFile } from 'node:fs/promises';

const root = path.dirname(fileURLToPath(import.meta.url));
const host = '127.0.0.1';
const port = Number(process.env.PORT || 4173);
const maxBody = 25 * 1024 * 1024;
let selectedOutputFolder = null;
const execFile = promisify((await import('node:child_process')).execFile);

function send(res, status, data, type = 'application/json; charset=utf-8') {
  res.writeHead(status, { 'Content-Type': type, 'X-Content-Type-Options': 'nosniff', 'Cache-Control': 'no-store' });
  res.end(type.startsWith('application/json') ? JSON.stringify(data) : data);
}

function videoId(input) {
  let url;
  try { url = new URL(input); } catch { throw new Error('Enter a valid YouTube video link.'); }
  const host = url.hostname.toLowerCase().replace(/^www\./, '').replace(/^m\./, '');
  let id = '';
  if (host === 'youtu.be') id = url.pathname.split('/').filter(Boolean)[0] || '';
  else if (['youtube.com', 'music.youtube.com'].includes(host)) {
    if (url.pathname === '/watch') id = url.searchParams.get('v') || '';
    else if (/^\/(shorts|embed|live)\//.test(url.pathname)) id = url.pathname.split('/')[2] || '';
  }
  if (!/^[\w-]{11}$/.test(id)) throw new Error('That does not look like a supported YouTube video URL.');
  return id;
}

function cleanFileName(input) {
  const name = input.replace(/[<>:"/\\|?*\x00-\x1f]/g, '-').trim().replace(/[. ]+$/g, '');
  if (!name || name === '.' || name === '..') throw new Error('Enter a valid file name.');
  const base = name.slice(0, 120);
  return base.toLowerCase().endsWith('.txt') ? base : `${base}.txt`;
}

async function readJson(req) {
  let body = '';
  for await (const chunk of req) {
    body += chunk;
    if (body.length > maxBody) throw new Error('Request is too large.');
  }
  return JSON.parse(body || '{}');
}

async function chooseWindowsFolder() {
  const ps = "$ErrorActionPreference='Stop'; Add-Type -AssemblyName System.Windows.Forms; $d=New-Object System.Windows.Forms.FolderBrowserDialog; $d.Description='Select the folder where YouTube transcripts should be saved'; $d.ShowNewFolderButton=$false; if($d.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){[Console]::OutputEncoding=[System.Text.Encoding]::UTF8; [Console]::Write($d.SelectedPath)}";
  const { stdout } = await execFile('powershell.exe', ['-NoProfile', '-STA', '-Command', ps], { windowsHide: false, timeout: 180_000, maxBuffer: 1024 * 1024, encoding: 'utf8' });
  return stdout.trim();
}

async function extract(url) {
  const id = videoId(url);
  const pythonScript = `import json, sys\nfrom youtube_transcript_api import YouTubeTranscriptApi\nvideo_id, url = sys.argv[1], sys.argv[2]\ntry:\n    fetched = YouTubeTranscriptApi().fetch(video_id, languages=['en', 'hi'])\nexcept Exception as first:\n    try:\n        tracks = YouTubeTranscriptApi().list(video_id)\n        track = next(iter(tracks), None)\n        if track is None:\n            raise first\n        fetched = track.fetch()\n    except Exception as exc:\n        print(json.dumps({'error': str(exc)}))\n        sys.exit(2)\ntext = ' '.join(part.text.replace('\\n', ' ').strip() for part in fetched if part.text.strip())\nif not text:\n    print(json.dumps({'error': 'The available caption track was empty.'}))\n    sys.exit(3)\nprint(json.dumps({'url': url, 'title': 'YouTube transcript', 'transcript': text, 'language': fetched.language}))`;
  let result;
  try {
    const { stdout } = await execFile('py', ['-3.11', '-c', pythonScript, id, url], { windowsHide: true, timeout: 120_000, maxBuffer: 20 * 1024 * 1024, encoding: 'utf8' });
    result = JSON.parse(stdout.trim());
  } catch (error) {
    const output = `${error.stdout || ''}\n${error.stderr || ''}`.trim();
    const match = output.match(/\{[\s\S]*\}/);
    if (match) {
      try { result = JSON.parse(match[0]); } catch { /* report the setup message below */ }
    }
    if (result?.error) throw new Error(result.error);
    if (error.code === 'ENOENT') throw new Error('Python 3.11 was not found. Install Python 3.11, then run Setup Agent.bat.');
    if (/No module named ['"]?youtube_transcript_api/i.test(output)) throw new Error('Transcript support is not installed yet. Close the app and run Setup Agent.bat once.');
    if (error.killed || error.code === 'ETIMEDOUT') throw new Error('YouTube took too long to return captions. Try this video again in a moment.');
    throw new Error(output.slice(-900) || 'Could not retrieve captions from YouTube.');
  }
  return result;
}

const server = http.createServer(async (req, res) => {
  const pathname = new URL(req.url, `http://${host}:${port}`).pathname;
  if (req.method === 'POST' && pathname === '/api/select-folder') {
    try {
      const selected = await chooseWindowsFolder();
      if (!selected) return send(res, 200, { cancelled: true });
      selectedOutputFolder = path.resolve(selected);
      return send(res, 200, { cancelled: false, path: selectedOutputFolder });
    } catch (error) { return send(res, 500, { error: `Could not open the Windows folder picker. ${error.message}` }); }
  }
  if (req.method === 'POST' && pathname === '/api/save-text') {
    try {
      const data = await readJson(req);
      if (!selectedOutputFolder) throw new Error('Choose a save folder first.');
      if (typeof data.content !== 'string') throw new Error('No transcript content was provided.');
      const filename = cleanFileName(String(data.name || ''));
      const target = path.resolve(selectedOutputFolder, filename);
      if (path.dirname(target) !== selectedOutputFolder) throw new Error('Invalid file name.');
      await writeFile(target, data.content, 'utf8');
      return send(res, 200, { saved: true, filename });
    } catch (error) { return send(res, 400, { error: error.message || 'Could not save the transcript.' }); }
  }
  if (req.method === 'POST' && pathname === '/api/transcript') {
    try {
      const data = await readJson(req);
      if (typeof data.url !== 'string' || data.url.length > 2048) throw new Error('Enter one YouTube link.');
      return send(res, 200, await extract(data.url));
    } catch (error) { return send(res, 400, { error: error.message || 'Transcript retrieval failed.' }); }
  }
  if (req.method !== 'GET' || !['/', '/index.html'].includes(pathname)) return send(res, 404, { error: 'Not found.' });
  try { send(res, 200, await readFile(path.join(root, 'index.html'), 'utf8'), 'text/html; charset=utf-8'); }
  catch { send(res, 500, 'The app page could not be opened.', 'text/plain; charset=utf-8'); }
});

function shutdown() {
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 2_000).unref();
}
process.once('SIGINT', shutdown);
process.once('SIGTERM', shutdown);

server.listen(port, host, () => {
  console.log(`YouTube Transcript Agent is ready at http://${host}:${port}`);
  if (process.env.NO_OPEN !== '1') {
    const child = spawn('cmd', ['/c', 'start', '', `http://${host}:${port}`], { stdio: 'ignore', windowsHide: true, detached: true });
    child.unref();
  }
});

server.on('error', error => {
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${port} is already in use. Close the other YouTube Transcript Agent window and try again.`);
  } else {
    console.error(`The agent could not start: ${error.message}`);
  }
  process.exitCode = 1;
});
