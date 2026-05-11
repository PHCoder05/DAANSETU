require('dotenv').config();
const { GoogleGenerativeAI } = require("@google/generative-ai");

async function verifyKey() {
  const apiKey = process.env.GEMINI_API_KEY;
  console.log('🔑 Key:', apiKey.substring(0, 10) + '...');
  
  const genAI = new GoogleGenerativeAI(apiKey);
  const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });

  try {
    const result = await model.generateContent("Hello, are you working?");
    const response = await result.response;
    console.log('✅ Response:', response.text());
  } catch (error) {
    console.error('❌ Error:', error.message);
    if (error.status) console.error('Status:', error.status);
  }
}

verifyKey();
