require('dotenv').config();
const { GoogleGenerativeAI } = require("@google/generative-ai");

async function testKey() {
  const apiKey = process.env.GEMINI_API_KEY;
  const genAI = new GoogleGenerativeAI(apiKey);
  
  try {
    console.log('Testing with: gemini-flash-latest');
    const model = genAI.getGenerativeModel({ model: "gemini-flash-latest" });
    const result = await model.generateContent("Hello");
    const response = await result.response;
    console.log('✅ Result:', response.text());
  } catch (error) {
    console.error('❌ Error details:');
    console.error(JSON.stringify(error, null, 2));
    console.error(error.message);
  }
}

testKey();
