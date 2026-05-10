const Donation = require('../models/Donation');
const logger = require('../utils/logger');
const { getDB } = require('../config/db');
const { ObjectId } = require('mongodb');

module.exports = (io) => {
    io.on('connection', (socket) => {
        
        // Join tracking room for a specific donation
        socket.on('join_tracking', (donationId) => {
            if (donationId) {
                const room = `tracking_${donationId}`;
                socket.join(room);
                logger.info(`Client ${socket.id} joined tracking room: ${room}`);
            }
        });

        // NGO broadcasts location updates
        socket.on('update_location', async (data) => {
            try {
                const { donationId, lat, lng } = data;
                
                if (!donationId || !lat || !lng) {
                    return;
                }

                const locationData = {
                    lat,
                    lng,
                    updatedAt: new Date().toISOString()
                };

                const room = `tracking_${donationId}`;
                
                // Broadcast to anyone listening to this donation
                io.to(room).emit('location_updated', {
                    donationId,
                    location: locationData
                });

                // Save to database (could be debounced or rate-limited in production)
                // For MVP, we save the latest location directly to the donation
                const db = getDB();
                await Donation.update(db, donationId, {
                    currentLocation: locationData
                });

            } catch (error) {
                logger.error('Error updating location:', error);
            }
        });

        // Global volunteer location tracking
        socket.on('volunteer_location_update', async (data) => {
            try {
                const { lat, lng, userId } = data;
                if (!lat || !lng || !userId) return;

                const db = getDB();
                await db.collection('users').updateOne(
                    { _id: new ObjectId(userId) },
                    { 
                        $set: { 
                            'location': { type: 'Point', coordinates: [lng, lat] },
                            'lastActive': new Date()
                        } 
                    }
                );
            } catch (error) {
                logger.error('Error updating volunteer global location:', error);
            }
        });

        // Leave tracking room
        socket.on('leave_tracking', (donationId) => {
            if (donationId) {
                const room = `tracking_${donationId}`;
                socket.leave(room);
                logger.info(`Client ${socket.id} left tracking room: ${room}`);
            }
        });
    });
};
