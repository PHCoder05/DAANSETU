require('dotenv').config();
const axios = require('axios');

async function testDirectHttp() {
  const apiKey = process.env.GEMINI_API_KEY;
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=${apiKey}`;

  console.log('📡 Testing direct HTTP call to v1beta...');
  
  try {
    const response = await axios.post(url, {
      contents: [{
        parts: [{ text: "Hi" }]
      }]
    });
    console.log('✅ Success:', response.data.candidates[0].content.parts[0].text);
  } catch (error) {
    console.error('❌ Error:', error.response ? error.response.status : error.message);
    if (error.response) {
      console.log('Error Data:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

testDirectHttp();
