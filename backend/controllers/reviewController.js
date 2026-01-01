const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const Review = require('../models/Review');
const Donation = require('../models/Donation');
const Notification = require('../models/Notification');
const { getPagination, buildPaginationResponse, successResponse, errorResponse } = require('../utils/helpers');
const logger = require('../utils/logger');

// Create review for NGO
const createReview = async (req, res) => {
  try {
    if (req.user.role !== 'donor') {
      return errorResponse(res, 403, 'Only donors can create reviews');
    }

    const { ngoId, donationId, rating, comment } = req.body;

    const db = getDB();

    // Verify donation exists and belongs to donor
    const donation = await Donation.findById(db, donationId);
    if (!donation) {
      return errorResponse(res, 404, 'Donation not found');
    }

    if (donation.donorId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'You can only review donations you created');
    }

    if (donation.status !== 'delivered') {
      return errorResponse(res, 400, 'You can only review after donation is delivered');
    }

    if (!donation.claimedBy || donation.claimedBy.toString() !== ngoId) {
      return errorResponse(res, 400, 'This NGO did not claim your donation');
    }

    // Check if review already exists
    const existingReview = await Review.checkExisting(db, req.user.userId, donationId);
    if (existingReview) {
      return errorResponse(res, 400, 'You have already reviewed this donation');
    }

    const reviewData = {
      donorId: req.user.userId,
      ngoId,
      donationId,
      rating,
      comment
    };

    const review = await Review.create(db, reviewData);

    // Create notification for NGO
    await Notification.create(db, {
      userId: new ObjectId(ngoId),
      title: 'New Review Received',
      message: `You received a ${rating}-star review from a donor`,
      type: 'review',
      relatedId: review._id,
      relatedType: 'review'
    });

    logger.info('Review created', {
      reviewId: review._id,
      donorId: req.user.userId,
      ngoId,
      rating
    });

    return successResponse(res, 201, 'Review created successfully', { review });
  } catch (error) {
    logger.logError(error, { action: 'createReview', userId: req.user.userId });
    return errorResponse(res, 500, 'Error creating review', error.message);
  }
};

// Get NGO reviews
const getNGOReviews = async (req, res) => {
  try {
    const { ngoId } = req.params;
    const { page = 1, limit = 10 } = req.query;
    const { skip, limit: limitNum } = getPagination(page, limit);

    const db = getDB();

    const reviews = await Review.findByNGO(db, ngoId, {
      skip,
      limit: limitNum,
      sort: { createdAt: -1 }
    });

    const total = await db.collection('reviews').countDocuments({
      ngoId: new ObjectId(ngoId),
      reported: false
    });

    const ratingData = await Review.getAverageRating(db, ngoId);

    return successResponse(
      res,
      200,
      'Reviews retrieved successfully',
      {
        ...buildPaginationResponse(reviews, total, page, limitNum),
        ...ratingData
      }
    );
  } catch (error) {
    logger.logError(error, { action: 'getNGOReviews', ngoId: req.params.ngoId });
    return errorResponse(res, 500, 'Error fetching reviews', error.message);
  }
};

// Update review (donor can edit their own review)
const updateReview = async (req, res) => {
  try {
    const { id } = req.params;
    const { rating, comment } = req.body;

    const db = getDB();

    const review = await Review.findById(db, id);
    if (!review) {
      return errorResponse(res, 404, 'Review not found');
    }

    if (review.donorId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'You can only update your own reviews');
    }

    const updateData = {};
    if (rating) updateData.rating = rating;
    if (comment !== undefined) updateData.comment = comment;

    await Review.update(db, id, updateData);

    const updatedReview = await Review.findById(db, id);

    return successResponse(res, 200, 'Review updated successfully', { review: updatedReview });
  } catch (error) {
    logger.logError(error, { action: 'updateReview', userId: req.user.userId });
    return errorResponse(res, 500, 'Error updating review', error.message);
  }
};

// Delete review
const deleteReview = async (req, res) => {
  try {
    const { id } = req.params;
    const db = getDB();

    const review = await Review.findById(db, id);
    if (!review) {
      return errorResponse(res, 404, 'Review not found');
    }

    if (review.donorId.toString() !== req.user.userId && req.user.role !== 'admin') {
      return errorResponse(res, 403, 'You do not have permission to delete this review');
    }

    await Review.delete(db, id);

    return successResponse(res, 200, 'Review deleted successfully');
  } catch (error) {
    logger.logError(error, { action: 'deleteReview', userId: req.user.userId });
    return errorResponse(res, 500, 'Error deleting review', error.message);
  }
};

// NGO respond to review
const respondToReview = async (req, res) => {
  try {
    if (req.user.role !== 'ngo') {
      return errorResponse(res, 403, 'Only NGOs can respond to reviews');
    }

    const { id } = req.params;
    const { response } = req.body;

    const db = getDB();

    const review = await Review.findById(db, id);
    if (!review) {
      return errorResponse(res, 404, 'Review not found');
    }

    if (review.ngoId.toString() !== req.user.userId) {
      return errorResponse(res, 403, 'You can only respond to reviews for your NGO');
    }

    await Review.update(db, id, {
      response,
      respondedAt: new Date()
    });

    const updatedReview = await Review.findById(db, id);

    return successResponse(res, 200, 'Response added successfully', { review: updatedReview });
  } catch (error) {
    logger.logError(error, { action: 'respondToReview', userId: req.user.userId });
    return errorResponse(res, 500, 'Error responding to review', error.message);
  }
};

module.exports = {
  createReview,
  getNGOReviews,
  updateReview,
  deleteReview,
  respondToReview
};

