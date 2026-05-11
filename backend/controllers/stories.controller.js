const ImpactStory = require('../models/ImpactStory');
const { getDB } = require('../config/db');

// GET /api/v1/stories - Get all published stories (social feed)
exports.getStories = async (req, res) => {
  try {
    const db = getDB();
    const { page = 1, limit = 10, category, ngoId } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const filter = {};
    if (category) filter.category = category;
    if (ngoId) filter.ngoId = require('mongodb').ObjectId.createFromHexString(ngoId);

    const [stories, total] = await Promise.all([
      ImpactStory.findAll(db, filter, { skip, limit: parseInt(limit) }),
      ImpactStory.count(db, filter)
    ]);

    // Mark which stories the current user has liked
    const userId = req.user?._id?.toString();
    const storiesWithLikeStatus = stories.map(story => ({
      ...story,
      isLikedByMe: userId ? (story.likes || []).some(id => id.toString() === userId) : false,
      likes: undefined // Don't send full likes array to client
    }));

    res.status(200).json({
      success: true,
      data: storiesWithLikeStatus,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total,
        pages: Math.ceil(total / parseInt(limit))
      }
    });
  } catch (error) {
    console.error('Get Stories Error:', error);
    res.status(500).json({ success: false, message: 'Failed to fetch stories' });
  }
};

// GET /api/v1/stories/:id - Get single story
exports.getStory = async (req, res) => {
  try {
    const db = getDB();
    const story = await ImpactStory.findById(db, req.params.id);
    if (!story) return res.status(404).json({ success: false, message: 'Story not found' });

    const userId = req.user?._id?.toString();
    const result = {
      ...story,
      isLikedByMe: userId ? (story.likes || []).some(id => id.toString() === userId) : false,
      likes: undefined
    };

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to fetch story' });
  }
};

// POST /api/v1/stories - Create a new impact story (NGO only)
exports.createStory = async (req, res) => {
  try {
    const db = getDB();
    const user = req.user;

    if (!['ngo', 'admin'].includes(user.role)) {
      return res.status(403).json({ success: false, message: 'Only NGOs can post impact stories' });
    }

    const { title, story, photos = [], category, beneficiariesCount, location, donationId } = req.body;

    if (!title || !story) {
      return res.status(400).json({ success: false, message: 'Title and story are required' });
    }

    // Limit to 5 photos
    const storyPhotos = photos.slice(0, 5);

    const newStory = await ImpactStory.create(db, {
      ngoId: user._id.toString(),
      donationId,
      title,
      story,
      photos: storyPhotos,
      category,
      beneficiariesCount: parseInt(beneficiariesCount) || 0,
      location
    });

    res.status(201).json({ success: true, data: newStory, message: 'Impact story published!' });
  } catch (error) {
    console.error('Create Story Error:', error);
    res.status(500).json({ success: false, message: 'Failed to create story' });
  }
};

// POST /api/v1/stories/:id/like - Toggle like on a story
exports.toggleLike = async (req, res) => {
  try {
    const db = getDB();
    const result = await ImpactStory.toggleLike(db, req.params.id, req.user._id.toString());
    if (!result) return res.status(404).json({ success: false, message: 'Story not found' });

    res.status(200).json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to toggle like' });
  }
};

// POST /api/v1/stories/:id/comment - Add a comment
exports.addComment = async (req, res) => {
  try {
    const db = getDB();
    const { text } = req.body;
    if (!text) return res.status(400).json({ success: false, message: 'Comment text required' });

    const comment = await ImpactStory.addComment(db, req.params.id, req.user._id.toString(), text);
    res.status(201).json({ success: true, data: comment });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to add comment' });
  }
};

// DELETE /api/v1/stories/:id - Delete a story (NGO owner or admin)
exports.deleteStory = async (req, res) => {
  try {
    const db = getDB();
    const story = await ImpactStory.findById(db, req.params.id);
    if (!story) return res.status(404).json({ success: false, message: 'Story not found' });

    const isOwner = story.ngoId.toString() === req.user._id.toString();
    if (!isOwner && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, message: 'Not authorized' });
    }

    await ImpactStory.delete(db, req.params.id);
    res.status(200).json({ success: true, message: 'Story deleted' });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Failed to delete story' });
  }
};
