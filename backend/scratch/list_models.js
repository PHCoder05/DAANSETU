require('dotenv').config();
const axios = require('axios');

async function listModels() {
  const apiKey = process.env.GEMINI_API_KEY;
  const url = `https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`;

  console.log('📡 Listing models...');
  
  try {
    const response = await axios.get(url);
    console.log('✅ Success! Models found:', response.data.models.length);
    response.data.models.forEach(m => console.log(` - ${m.name}`));
  } catch (error) {
    console.error('❌ Error:', error.response ? error.response.status : error.message);
    if (error.response) {
      console.log('Error Data:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

listModels();
