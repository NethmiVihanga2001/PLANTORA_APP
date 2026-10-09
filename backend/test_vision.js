const dotenv = require('dotenv');
const path = require('path');
const fs = require('fs');
const { GoogleGenerativeAI } = require('@google/generative-ai');

dotenv.config({ path: path.join(__dirname, '.env') });

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

async function testVision() {
  const models = ['gemini-flash-latest', 'gemini-3.5-flash', 'gemini-pro-latest', 'gemini-2.5-pro', 'gemini-2.5-flash-lite'];
  
  // Create dummy image buffer
  const sampleImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==";

  const imageParts = [
    {
      inlineData: {
        data: sampleImageBase64,
        mimeType: "image/png"
      }
    }
  ];

  const prompt = "Identify the plant in this image. Return JSON format: {'commonName': 'Name', 'species': 'Species', 'description': 'Summary'}";

  for (const m of models) {
    try {
      console.log(`Testing Vision on model "${m}"...`);
      const model = genAI.getGenerativeModel({ model: m });
      const res = await model.generateContent([prompt, ...imageParts]);
      console.log(`SUCCESS [${m}]:`, res.response.text());
      return m;
    } catch (err) {
      console.error(`FAILED [${m}]:`, err.message);
    }
  }
}

testVision();
