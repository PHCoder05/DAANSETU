const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/daansetu';
const DB_NAME = process.env.DB_NAME || 'daansetu';

async function seedVerifiedNGO() {
    console.log('🌱 Seeding verified NGO...');
    const client = new MongoClient(MONGODB_URI);
    try {
        await client.connect();
        const db = client.db(DB_NAME);

        const password = await bcrypt.hash('@Ngo24', 10);
        const ngoUser = {
            email: 'ngo@daansetu.com',
            password: password,
            name: 'Helping Hands Foundation',
            role: 'ngo',
            verified: true,
            active: true,
            isVerifiedNgo: true,
            ngoDetails: {
                registrationNumber: 'NGO-12345',
                verificationStatus: 'verified',
                description: 'A leading NGO for child welfare and food distribution.',
                address: '123, Charity Lane, Pune'
            },
            createdAt: new Date(),
            updatedAt: new Date()
        };

        const existing = await db.collection('users').findOne({ email: ngoUser.email });
        if (existing) {
            console.log(`Updating existing NGO: ${ngoUser.email}`);
            await db.collection('users').updateOne({ _id: existing._id }, { $set: ngoUser });
        } else {
            console.log(`Creating new Verified NGO: ${ngoUser.email}`);
            await db.collection('users').insertOne(ngoUser);
        }
        
        console.log('\n────────────────────────────────────');
        console.log('✅ NGO Account Ready!');
        console.log('📧 Email: ngo@daansetu.com');
        console.log('🔐 Password: @Ngo24');
        console.log('────────────────────────────────────');

    } catch (err) {
        console.error('❌ Seeding failed:', err);
    } finally {
        await client.close();
    }
}

seedVerifiedNGO();
