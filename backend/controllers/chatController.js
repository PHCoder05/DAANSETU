const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');
const Message = require('../models/Message');
const { successResponse, errorResponse } = require('../utils/helpers');

// Get chat history with a specific user
const getChatHistory = async (req, res) => {
    try {
        const { recipientId } = req.params;
        const currentUserId = req.user.userId;
        const db = getDB();

        if (!recipientId) {
            return errorResponse(res, 400, 'Recipient ID is required');
        }

        const messages = await Message.findHistory(db, currentUserId, recipientId);
        return successResponse(res, 200, 'Chat history retrieved successfully', { messages });
    } catch (error) {
        console.error('Get chat history error:', error);
        return errorResponse(res, 500, 'Error fetching chat history', error.message);
    }
};

// Get chat history for a specific donation
const getChatByDonation = async (req, res) => {
    try {
        const { donationId, recipientId } = req.params;
        const currentUserId = req.user.userId;
        const db = getDB();

        if (!donationId || !recipientId) {
            return errorResponse(res, 400, 'Donation ID and Recipient ID are required');
        }

        const messages = await Message.findHistoryByDonation(db, currentUserId, recipientId, donationId);
        return successResponse(res, 200, 'Chat history retrieved successfully', { messages });
    } catch (error) {
        console.error('Get chat by donation error:', error);
        return errorResponse(res, 500, 'Error fetching chat history', error.message);
    }
};

// Get list of conversations (by user)
const getConversations = async (req, res) => {
    try {
        const currentUserId = req.user.userId;
        const db = getDB();

        const conversations = await db.collection('messages').aggregate([
            {
                $match: {
                    $or: [
                        { sender: new ObjectId(currentUserId) },
                        { recipient: new ObjectId(currentUserId) }
                    ]
                }
            },
            { $sort: { createdAt: -1 } },
            {
                $group: {
                    _id: {
                        $cond: [
                            { $eq: ["$sender", new ObjectId(currentUserId)] },
                            "$recipient",
                            "$sender"
                        ]
                    },
                    lastMessage: { $first: "$$ROOT" },
                    unreadCount: {
                        $sum: {
                            $cond: [
                                {
                                    $and: [
                                        { $eq: ["$recipient", new ObjectId(currentUserId)] },
                                        { $eq: ["$read", false] }
                                    ]
                                },
                                1,
                                0
                            ]
                        }
                    }
                }
            },
            {
                $lookup: {
                    from: "users",
                    localField: "_id",
                    foreignField: "_id",
                    as: "otherUser"
                }
            },
            { $unwind: "$otherUser" },
            {
                $project: {
                    _id: 1,
                    lastMessage: {
                        _id: 1,
                        content: 1,
                        createdAt: 1,
                        read: 1,
                        sender: 1,
                        donationId: 1
                    },
                    unreadCount: 1,
                    otherUser: {
                        _id: 1,
                        name: 1,
                        profileImage: 1,
                        role: 1
                    }
                }
            },
            { $sort: { "lastMessage.createdAt": -1 } }
        ]).toArray();

        return successResponse(res, 200, 'Conversations retrieved successfully', { conversations });
    } catch (error) {
        console.error('Get conversations error:', error);
        return errorResponse(res, 500, 'Error fetching conversations', error.message);
    }
};

// Get conversations grouped by donation
const getConversationsByDonation = async (req, res) => {
    try {
        const currentUserId = req.user.userId;
        const db = getDB();

        const conversations = await Message.getConversationsByDonation(db, currentUserId);
        return successResponse(res, 200, 'Conversations by donation retrieved', { conversations });
    } catch (error) {
        console.error('Get conversations by donation error:', error);
        return errorResponse(res, 500, 'Error fetching conversations', error.message);
    }
};

// Mark messages as read
const markAsRead = async (req, res) => {
    try {
        const { recipientId } = req.params;
        const { donationId } = req.query;
        const currentUserId = req.user.userId;
        const db = getDB();

        const result = await Message.markAsRead(db, recipientId, currentUserId, donationId);

        return successResponse(res, 200, 'Messages marked as read', {
            modifiedCount: result.modifiedCount
        });
    } catch (error) {
        console.error('Mark as read error:', error);
        return errorResponse(res, 500, 'Error marking messages as read', error.message);
    }
};

module.exports = {
    getChatHistory,
    getChatByDonation,
    getConversations,
    getConversationsByDonation,
    markAsRead
};
