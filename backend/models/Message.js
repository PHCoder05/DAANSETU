const { ObjectId } = require('mongodb');

class Message {
    constructor(data) {
        this.sender = new ObjectId(data.sender);
        this.recipient = new ObjectId(data.recipient);
        this.content = data.content;
        this.donationId = data.donationId ? new ObjectId(data.donationId) : null;
        this.read = data.read || false;
        this.createdAt = data.createdAt || new Date();
    }

    static collectionName = 'messages';

    static async create(db, messageData) {
        const message = new Message(messageData);
        const result = await db.collection(this.collectionName).insertOne(message);
        return { ...message, _id: result.insertedId };
    }

    /**
     * Find chat history between two users (all messages)
     */
    static async findHistory(db, userId1, userId2, limit = 50) {
        return await db.collection(this.collectionName)
            .aggregate([
                {
                    $match: {
                        $or: [
                            { sender: new ObjectId(userId1), recipient: new ObjectId(userId2) },
                            { sender: new ObjectId(userId2), recipient: new ObjectId(userId1) }
                        ]
                    }
                },
                { $sort: { createdAt: 1 } },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'sender',
                        foreignField: '_id',
                        as: 'senderDetails'
                    }
                },
                { $unwind: '$senderDetails' },
                {
                    $project: {
                        content: 1,
                        read: 1,
                        createdAt: 1,
                        donationId: 1,
                        sender: {
                            _id: '$senderDetails._id',
                            name: '$senderDetails.name',
                            profileImage: '$senderDetails.profileImage'
                        },
                        recipient: 1
                    }
                }
            ])
            .toArray();
    }

    /**
     * Find chat history for a specific donation
     */
    static async findHistoryByDonation(db, userId1, userId2, donationId, limit = 100) {
        return await db.collection(this.collectionName)
            .aggregate([
                {
                    $match: {
                        donationId: new ObjectId(donationId),
                        $or: [
                            { sender: new ObjectId(userId1), recipient: new ObjectId(userId2) },
                            { sender: new ObjectId(userId2), recipient: new ObjectId(userId1) }
                        ]
                    }
                },
                { $sort: { createdAt: 1 } },
                { $limit: limit },
                {
                    $lookup: {
                        from: 'users',
                        localField: 'sender',
                        foreignField: '_id',
                        as: 'senderDetails'
                    }
                },
                { $unwind: '$senderDetails' },
                {
                    $project: {
                        content: 1,
                        read: 1,
                        createdAt: 1,
                        donationId: 1,
                        sender: {
                            _id: '$senderDetails._id',
                            name: '$senderDetails.name',
                            profileImage: '$senderDetails.profileImage'
                        },
                        recipient: 1
                    }
                }
            ])
            .toArray();
    }

    /**
     * Get all conversations grouped by donation
     */
    static async getConversationsByDonation(db, userId) {
        return await db.collection(this.collectionName)
            .aggregate([
                {
                    $match: {
                        $or: [
                            { sender: new ObjectId(userId) },
                            { recipient: new ObjectId(userId) }
                        ],
                        donationId: { $ne: null }
                    }
                },
                {
                    $group: {
                        _id: '$donationId',
                        lastMessage: { $last: '$$ROOT' },
                        unreadCount: {
                            $sum: {
                                $cond: [
                                    {
                                        $and: [
                                            { $eq: ['$recipient', new ObjectId(userId)] },
                                            { $eq: ['$read', false] }
                                        ]
                                    },
                                    1,
                                    0
                                ]
                            }
                        }
                    }
                },
                { $sort: { 'lastMessage.createdAt': -1 } },
                {
                    $lookup: {
                        from: 'donations',
                        localField: '_id',
                        foreignField: '_id',
                        as: 'donation'
                    }
                },
                { $unwind: '$donation' }
            ])
            .toArray();
    }

    /**
     * Mark messages as read
     */
    static async markAsRead(db, senderId, recipientId, donationId = null) {
        const filter = {
            sender: new ObjectId(senderId),
            recipient: new ObjectId(recipientId),
            read: false
        };

        if (donationId) {
            filter.donationId = new ObjectId(donationId);
        }

        return await db.collection(this.collectionName).updateMany(
            filter,
            { $set: { read: true } }
        );
    }
}

module.exports = Message;

