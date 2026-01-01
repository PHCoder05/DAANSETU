const Message = require('../models/Message');
const logger = require('../utils/logger');
const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');

module.exports = (io) => {
    // Track connected users for online status
    const connectedUsers = new Map();

    io.on('connection', (socket) => {
        logger.info(`🔌 New client connected: ${socket.id}`);

        // User joins with their userId
        socket.on('user_connected', (userId) => {
            if (userId) {
                connectedUsers.set(userId, socket.id);
                socket.userId = userId;
                socket.join(userId); // Join personal room
                logger.info(`User ${userId} connected with socket ${socket.id}`);

                // Broadcast online status
                io.emit('user_online', { userId, online: true });
            }
        });

        // Join a specific chat room (for donation-based chats)
        socket.on('join_room', (room) => {
            socket.join(room);
            logger.info(`Client ${socket.id} joined room: ${room}`);
        });

        // Handle sending messages
        socket.on('send_message', async (data) => {
            try {
                const { sender, recipient, content, donationId } = data;
                const db = getDB();

                // Validate required fields
                if (!sender || !recipient || !content) {
                    socket.emit('error', { message: 'Missing required fields' });
                    return;
                }

                // Save to database
                const newMessage = await Message.create(db, {
                    sender,
                    recipient,
                    content,
                    donationId
                });

                // Lookup sender details for display
                const senderDetails = await db.collection('users').findOne(
                    { _id: new ObjectId(sender) },
                    { projection: { name: 1, profileImage: 1, role: 1 } }
                );

                // Build response message with sender info
                const messageWithSender = {
                    ...newMessage,
                    sender: senderDetails || { _id: sender, name: 'Unknown' },
                    createdAt: newMessage.createdAt.toISOString()
                };

                // Emit to recipient's room
                io.to(recipient).emit('receive_message', messageWithSender);

                // Confirm to sender
                socket.emit('message_sent', messageWithSender);

                logger.info(`Message sent from ${sender} to ${recipient}`);
            } catch (error) {
                logger.error('Error sending message:', error);
                socket.emit('error', { message: 'Failed to send message' });
            }
        });

        // Handle typing indicators
        socket.on('typing', (data) => {
            const { recipient, isTyping } = data;
            if (recipient) {
                io.to(recipient).emit('typing_status', {
                    sender: socket.userId,
                    isTyping
                });
            }
        });

        // Handle disconnect
        socket.on('disconnect', () => {
            if (socket.userId) {
                connectedUsers.delete(socket.userId);
                io.emit('user_online', { userId: socket.userId, online: false });
            }
            logger.info(`🔌 Client disconnected: ${socket.id}`);
        });
    });
};

