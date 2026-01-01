/**
 * Reset Admin Password Script
 * Resets the admin password to default
 * Run with: node scripts/reset-admin-password.js
 */

require('dotenv').config();
const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/daansetu';
const NEW_PASSWORD = 'Admin@123';

async function resetAdminPassword() {
    let client;

    try {
        console.log('🔄 Connecting to MongoDB...');
        client = new MongoClient(MONGODB_URI);
        await client.connect();
        console.log('✅ Connected to MongoDB');

        const db = client.db();
        const usersCollection = db.collection('users');

        // Find admin user
        const admin = await usersCollection.findOne({ email: 'admin@daansetu.org' });

        if (!admin) {
            console.log('❌ Admin user not found!');
            return;
        }

        console.log('👤 Found admin:', admin.name);

        // Hash new password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(NEW_PASSWORD, salt);

        // Update password
        await usersCollection.updateOne(
            { email: 'admin@daansetu.org' },
            { $set: { password: hashedPassword, updatedAt: new Date() } }
        );

        console.log('✅ Admin password reset successfully!');
        console.log('────────────────────────────────────');
        console.log('📧 Email: admin@daansetu.org');
        console.log('🔐 New Password:', NEW_PASSWORD);
        console.log('────────────────────────────────────');

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    } finally {
        if (client) {
            await client.close();
            console.log('🔌 Disconnected from MongoDB');
        }
    }
}

resetAdminPassword();
