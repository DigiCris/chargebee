import http from 'node:http';
import fs from 'node:fs';

const port = Number(process.env.PORT || 8787);
fs.mkdirSync('data', { recursive: true });

const server = http.createServer((req, res) => {
  if (req.method !== 'POST' || req.url !== '/chargebee/webhook') {
    res.writeHead(404, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'not_found' }));
    return;
  }

  let body = '';
  req.on('data', chunk => { body += chunk; });
  req.on('end', () => {
    const file = `data/webhook-${Date.now()}.json`;
    fs.writeFileSync(file, body || '{}');
    console.log(`Webhook saved to ${file}`);
    console.log(body);
    res.writeHead(200, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ ok: true }));
  });
});

server.listen(port, () => {
  console.log(`Mock webhook receiver listening on http://localhost:${port}/chargebee/webhook`);
});
