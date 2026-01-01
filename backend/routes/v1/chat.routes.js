const express = require('express');
const router = express.Router();
const chatController = require('../../controllers/chatController');
const { authenticate } = require('../../middleware/auth');

/**
 * @swagger
 * /api/v1/chat/history/{recipientId}:
 *   get:
 *     summary: Get chat history with a user
 *     tags: [Chat]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: recipientId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Chat history retrieved
 */
router.get('/history/:recipientId', authenticate, chatController.getChatHistory);

/**
 * @swagger
 * /api/v1/chat/donation/{donationId}/{recipientId}:
 *   get:
 *     summary: Get chat history for a specific donation
 *     tags: [Chat]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: donationId
 *         required: true
 *         schema:
 *           type: string
 *       - in: path
 *         name: recipientId
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Chat history for donation retrieved
 */
router.get('/donation/:donationId/:recipientId', authenticate, chatController.getChatByDonation);

/**
 * @swagger
 * /api/v1/chat/conversations:
 *   get:
 *     summary: Get list of conversations (grouped by user)
 *     tags: [Chat]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of conversations
 */
router.get('/conversations', authenticate, chatController.getConversations);

/**
 * @swagger
 * /api/v1/chat/conversations/by-donation:
 *   get:
 *     summary: Get list of conversations grouped by donation
 *     tags: [Chat]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of conversations by donation
 */
router.get('/conversations/by-donation', authenticate, chatController.getConversationsByDonation);

/**
 * @swagger
 * /api/v1/chat/read/{recipientId}:
 *   put:
 *     summary: Mark messages from a user as read
 *     tags: [Chat]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: recipientId
 *         required: true
 *         schema:
 *           type: string
 *       - in: query
 *         name: donationId
 *         schema:
 *           type: string
 *         description: Optional - filter by donation
 *     responses:
 *       200:
 *         description: Messages marked as read
 */
router.put('/read/:recipientId', authenticate, chatController.markAsRead);

module.exports = router;
