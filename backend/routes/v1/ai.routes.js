const express = require('express');
const router = express.Router();
const aiController = require('../../controllers/ai.controller');
const { authenticate } = require('../../middleware/auth');

// POST /api/v1/ai/analyze - Analyze donation image
router.post('/analyze', authenticate, aiController.analyzeImage);

// POST /api/v1/ai/voice-search - Parse natural language search query
router.post('/voice-search', authenticate, aiController.voiceSearch);

// POST /api/v1/ai/voice-form - Parse natural language donation description
router.post('/voice-form', authenticate, aiController.parseVoiceDonation);

// POST /api/v1/ai/chat - Natural language conversation with Gemini
router.post('/chat', authenticate, aiController.chat);

// POST /api/v1/ai/match - Recommend best NGOs for a donation
router.post('/match', authenticate, aiController.recommendNGOs);

module.exports = router;
