const http = require('http');
const fs = require('fs');
const path = require('path');

const imgPath = path.join(__dirname, '..', 'assets', 'images', 'onboarding_plant_id.jpg');
const imgBuffer = fs.readFileSync(imgPath);

const boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
const header = '--' + boundary + '\r\n' +
  'Content-Disposition: form-data; name="message"\r\n\r\n' +
  'what is this\r\n' +
  '--' + boundary + '\r\n' +
  'Content-Disposition: form-data; name="image"; filename="plant.jpg"\r\n' +
  'Content-Type: application/octet-stream\r\n\r\n'; // Mobile device sending octet-stream

const footer = '\r\n--' + boundary + '--\r\n';

const headerBuf = Buffer.from(header);
const footerBuf = Buffer.from(footer);
const fullPayload = Buffer.concat([headerBuf, imgBuffer, footerBuf]);

const req = http.request({
  hostname: 'localhost',
  port: 3000,
  path: '/api/ai/chat',
  method: 'POST',
  headers: {
    'Content-Type': 'multipart/form-data; boundary=' + boundary,
    'Content-Length': fullPayload.length
  }
}, res => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Gemini Live Vision Identification Response:\n', JSON.parse(data).reply);
  });
});

req.write(fullPayload);
req.end();
