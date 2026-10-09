const dotenv = require('dotenv');
const path = require('path');
const https = require('https');

dotenv.config({ path: path.join(__dirname, '../backend/.env') });

const apiKey = process.env.GEMINI_API_KEY;
console.log('Testing GEMINI_API_KEY:', apiKey ? apiKey.substring(0, 8) + '...' : 'NONE');

const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;

https.get(url, (res) => {
  let body = '';
  res.on('data', chunk => body += chunk);
  res.on('end', () => {
    try {
      const json = JSON.parse(body);
      console.log('Models available:');
      if (json.models) {
        json.models.forEach(m => {
          if (m.supportedGenerationMethods && m.supportedGenerationMethods.includes('generateContent')) {
            console.log(' - ' + m.name);
          }
        });
      } else {
        console.log(json);
      }
    } catch (e) {
      console.error(e, body);
    }
  });
}).on('error', (e) => {
  console.error(e);
});
