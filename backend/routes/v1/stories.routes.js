const express = require('express');
const router = express.Router();
const storiesController = require('../../controllers/stories.controller');
const { authenticate } = require('../../middleware/auth');

// Public feed
router.get('/', authenticate, storiesController.getStories);
router.get('/:id', authenticate, storiesController.getStory);

// NGO actions
router.post('/', authenticate, storiesController.createStory);
router.delete('/:id', authenticate, storiesController.deleteStory);

// Engagement
router.post('/:id/like', authenticate, storiesController.toggleLike);
router.post('/:id/comment', authenticate, storiesController.addComment);

module.exports = router;
