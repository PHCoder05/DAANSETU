require('dotenv').config();
const aiService = require('../services/ai.service');

async function testAI() {
  console.log('🚀 Starting AI Analysis Test...');
  
  // A tiny valid base64 image (1x1 transparent pixel)
  // In a real test, this would be a photo of clothes/food
  const sampleBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

  try {
    console.log('📡 Calling Gemini API...');
    const result = await aiService.analyzeDonationImage(sampleBase64);
    
    console.log('\n✅ AI Response Received:');
    console.log(JSON.stringify(result, null, 2));

    const expectedKeys = ['title', 'description', 'category', 'estimatedQuantity', 'suggestedUnit', 'urgency'];
    const missingKeys = expectedKeys.filter(key => !result.hasOwnProperty(key));

    if (missingKeys.length === 0) {
      console.log('\n✨ SUCCESS: All expected fields are present!');
    } else {
      console.log('\n⚠️ WARNING: Missing fields:', missingKeys.join(', '));
    }

  } catch (error) {
    console.error('\n❌ Test Failed:', error.message);
  }
}

testAI();
