/**
 * Admin Seed Script
 * Creates a super admin user in the database
 * Run with: node scripts/seed-admin.js
 */

require('dotenv').config();
const { MongoClient } = require('mongodb');
const bcrypt = require('bcryptjs');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/daansetu';

const ADMIN_USER = {
    email: 'admin@daansetu.org',
    password: 'Admin@123', // Change this in production!
    name: 'Super Admin',
    role: 'admin',
    phone: '+91-9999999999',
    address: 'DAANSETU Headquarters',
    verified: true,
    active: true,
    isAdmin: true,
    adminDetails: {
        level: 'super_admin',
        permissions: [
            'manage_users',
            'verify_ngos',
            'manage_donations',
            'manage_requests',
            'view_analytics',
            'system_settings'
        ],
        createdBy: 'system'
    },
    createdAt: new Date(),
    updatedAt: new Date()
};

async function seedAdmin() {
    let client;

    try {
        console.log('🔄 Connecting to MongoDB...');
        client = new MongoClient(MONGODB_URI);
        await client.connect();
        console.log('✅ Connected to MongoDB');

        const db = client.db();
        const usersCollection = db.collection('users');

        // Check if admin already exists
        const existingAdmin = await usersCollection.findOne({ email: ADMIN_USER.email });

        if (existingAdmin) {
            console.log('⚠️  Admin user already exists with email:', ADMIN_USER.email);
            console.log('📧 Email:', existingAdmin.email);
            console.log('👤 Name:', existingAdmin.name);
            console.log('🔑 Role:', existingAdmin.role);
            return;
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(ADMIN_USER.password, salt);

        const adminData = {
            ...ADMIN_USER,
            password: hashedPassword
        };

        // Insert admin user
        const result = await usersCollection.insertOne(adminData);

        console.log('✅ Super Admin created successfully!');
        console.log('────────────────────────────────────');
        console.log('📧 Email:', ADMIN_USER.email);
        console.log('🔐 Password:', ADMIN_USER.password);
        console.log('👤 Name:', ADMIN_USER.name);
        console.log('🔑 Role:', ADMIN_USER.role);
        console.log('🆔 ID:', result.insertedId);
        console.log('────────────────────────────────────');
        console.log('⚠️  IMPORTANT: Change the password after first login!');

    } catch (error) {
        console.error('❌ Error seeding admin:', error);
        process.exit(1);
    } finally {
        if (client) {
            await client.close();
            console.log('🔌 Disconnected from MongoDB');
        }
    }
}

// Run the seed
seedAdmin();
