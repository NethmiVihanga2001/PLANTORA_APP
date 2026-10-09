const dotenv = require('dotenv');
const path = require('path');
const { GoogleGenerativeAI } = require('@google/generative-ai');

dotenv.config({ path: path.join(__dirname, '.env') });

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

async function testModels() {
  const models = ['gemini-2.5-flash', 'gemini-flash-latest', 'gemini-3.5-flash', 'gemini-pro-latest'];
  
  for (const m of models) {
    try {
      console.log(`Testing model "${m}"...`);
      const model = genAI.getGenerativeModel({ model: m });
      const res = await model.generateContent(["Identify this plant in 1 sentence: Rose."]);
      console.log(`SUCCESS [${m}]:`, res.response.text());
      return m;
    } catch (err) {
      console.error(`FAILED [${m}]:`, err.message);
    }
  }
}

testModels();
