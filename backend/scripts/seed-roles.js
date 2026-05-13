const { MongoClient, ObjectId } = require('mongodb');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI;
const DB_NAME = process.env.DB_NAME || 'daansetu';

async function seedRoles() {
    console.log('🌱 Seeding roles for audit...');
    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    const db = client.db(DB_NAME);

    const users = [
        {
            email: 'admin@daansetu.com',
            password: await bcrypt.hash('@Admin24', 10),
            name: 'Platform Admin',
            role: 'admin',
            verified: true,
            active: true
        },
        {
            email: 'volunteer@daansetu.com',
            password: await bcrypt.hash('@Volunteer24', 10),
            name: 'City Volunteer',
            role: 'volunteer',
            verified: true,
            active: true,
            location: { lat: 18.52, lng: 73.85, address: 'Pune, Maharashtra' },
            volunteerStats: { pickupsCompleted: 5, totalPoints: 100, rating: 4.8 }
        },
        {
            email: 'pending_ngo@daansetu.com',
            password: await bcrypt.hash('@PendingNGO24', 10),
            name: 'New NGO',
            role: 'ngo',
            verified: false,
            active: true,
            ngoDetails: {
                registrationNumber: 'NGO-PEND-001',
                verificationStatus: 'pending',
                description: 'Awaiting verification'
            }
        }
    ];

    try {
        for (const user of users) {
            const existing = await db.collection('users').findOne({ email: user.email });
            if (existing) {
                console.log(`Updating existing user: ${user.email}`);
                await db.collection('users').updateOne({ _id: existing._id }, { $set: user });
            } else {
                console.log(`Creating new user: ${user.email}`);
                await db.collection('users').insertOne(user);
            }
        }
        console.log('✅ Role seeding completed.');
    } catch (err) {
        console.error('❌ Seeding failed:', err);
    } finally {
        await client.close();
    }
}

seedRoles();
