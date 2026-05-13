const aiService = require('../services/ai.service');

exports.analyzeImage = async (req, res) => {
  try {
    const { image } = req.body;
    if (!image) {
      return res.status(400).json({
        success: false,
        message: 'Image is required'
      });
    }

    const analysis = await aiService.analyzeDonationImage(image);
    
    res.status(200).json({
      success: true,
      data: analysis
    });
  } catch (error) {
    console.error('AI Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to analyze image'
    });
  }
};

exports.voiceSearch = async (req, res) => {
  try {
    const { query } = req.body;
    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Query is required'
      });
    }

    const filters = await aiService.parseVoiceSearch(query);
    
    res.status(200).json({
      success: true,
      data: filters
    });
  } catch (error) {
    console.error('AI Voice Search Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to parse voice query'
    });
  }
};

exports.parseVoiceDonation = async (req, res) => {
  try {
    const { query } = req.body;
    if (!query) {
      return res.status(400).json({
        success: false,
        message: 'Query is required'
      });
    }

    const donationData = await aiService.parseVoiceDonation(query);
    
    res.status(200).json({
      success: true,
      data: donationData
    });
  } catch (error) {
    console.error('AI Voice Donation Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to parse voice donation description'
    });
  }
};

exports.chat = async (req, res) => {
  try {
    const { message, history } = req.body;
    if (!message) {
      return res.status(400).json({
        success: false,
        message: 'Message is required'
      });
    }

    const reply = await aiService.chat(message, history, req.user._id);
    
    res.status(200).json({
      success: true,
      data: reply
    });
  } catch (error) {
    console.error('AI Chat Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get AI reply'
    });
  }
};

exports.recommendNGOs = async (req, res) => {
  try {
    const { category, lat, lng } = req.body;
    const { getDB } = require('../config/db');
    const db = getDB();

    const recommendations = await aiService.recommendNGOs(db, { category }, lat, lng);
    
    res.status(200).json({
      success: true,
      data: recommendations
    });
  } catch (error) {
    console.error('AI Recommendation Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get recommendations'
    });
  }
};
exports.getAdminAnalytics = async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Admin access required' });
    }

    const { getDB } = require('../config/db');
    const db = getDB();
    
    const analysis = await aiService.getAdminAnalytics(db);
    
    res.status(200).json({
      success: true,
      data: analysis
    });
  } catch (error) {
    console.error('AI Analytics Controller Error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to generate AI analytics'
    });
  }
};
