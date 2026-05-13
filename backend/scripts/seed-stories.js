const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config();

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/daansetu';
const DB_NAME = process.env.DB_NAME || 'daansetu';

async function seedStories() {
    console.log('🌱 Seeding impact stories...');
    const client = new MongoClient(MONGODB_URI);
    try {
        await client.connect();
        const db = client.db(DB_NAME);

        // 1. Find an NGO
        let ngo = await db.collection('users').findOne({ role: 'ngo' });
        if (!ngo) {
            console.log('No NGO found. Creating a dummy NGO...');
            const insertRes = await db.collection('users').insertOne({
                email: 'impact_ngo@daansetu.com',
                name: 'Hope Foundation',
                role: 'ngo',
                verified: true,
                active: true,
                ngoDetails: { verificationStatus: 'verified' }
            });
            ngo = { _id: insertRes.insertedId, name: 'Hope Foundation' };
        } else {
            console.log(`Found NGO: ${ngo.name} (${ngo._id})`);
        }

        // 2. Find some donations (optional, for linking)
        const donations = await db.collection('donations').find({}).limit(5).toArray();

        const stories = [
            {
                ngoId: ngo._id,
                donationId: donations.length > 0 ? donations[0]._id : null,
                title: 'Fed 50 Children at the Orphanage',
                story: 'Thanks to the generous donation of 50kg of rice and lentils, we were able to provide hot, nutritious meals for a week to 50 children at the Sunshine Orphanage. The smiles on their faces were priceless. Your contributions make a real difference in these children\'s lives.',
                photos: ['https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?q=80&w=1000'],
                category: 'food',
                beneficiariesCount: 50,
                location: { city: 'Pune', state: 'Maharashtra' },
                likes: [],
                likesCount: 12,
                comments: [
                    { userId: new ObjectId(), text: 'This is so heartwarming!', createdAt: new Date(Date.now() - 86400000) }
                ],
                isPublished: true,
                createdAt: new Date(Date.now() - 172800000), // 2 days ago
                updatedAt: new Date(Date.now() - 172800000)
            },
            {
                ngoId: ngo._id,
                donationId: donations.length > 1 ? donations[1]._id : null,
                title: 'Winter Clothes Distribution Drive',
                story: 'The winter clothes collection was a huge success. We distributed over 200 warm jackets and blankets to the homeless community in the downtown area. The dropping temperatures are brutal, and these clothes will provide much-needed warmth. Thank you to everyone who cleaned out their closets for this cause!',
                photos: ['https://images.unsplash.com/photo-1489987707023-afc824781ef1?q=80&w=1000'],
                category: 'clothes',
                beneficiariesCount: 200,
                location: { city: 'Mumbai', state: 'Maharashtra' },
                likes: [],
                likesCount: 34,
                comments: [],
                isPublished: true,
                createdAt: new Date(Date.now() - 432000000), // 5 days ago
                updatedAt: new Date(Date.now() - 432000000)
            },
            {
                ngoId: ngo._id,
                donationId: donations.length > 2 ? donations[2]._id : null,
                title: 'Medical Camp in Slum Area',
                story: 'With the donated medical supplies and first aid kits, we successfully conducted a basic health checkup camp. We were able to treat minor injuries and provide basic health education to over 100 families. Access to these simple supplies prevents infections and saves lives.',
                photos: ['https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=1000'],
                category: 'medical',
                beneficiariesCount: 100,
                location: { city: 'Pune', state: 'Maharashtra' },
                likes: [],
                likesCount: 8,
                comments: [],
                isPublished: true,
                createdAt: new Date(Date.now() - 604800000), // 7 days ago
                updatedAt: new Date(Date.now() - 604800000)
            },
            {
                ngoId: ngo._id,
                donationId: donations.length > 3 ? donations[3]._id : null,
                title: 'Library Setup for Rural School',
                story: 'The donated textbooks and storybooks have found a new home! We set up a small library in a rural school that previously had no reading materials. The kids are incredibly excited to read the stories. Education is the best gift.',
                photos: ['https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?q=80&w=1000'],
                category: 'books',
                beneficiariesCount: 150,
                location: { city: 'Satara', state: 'Maharashtra' },
                likes: [],
                likesCount: 22,
                comments: [],
                isPublished: true,
                createdAt: new Date(), // Just now
                updatedAt: new Date()
            }
        ];

        // Clear existing stories for a fresh start (optional, but good for testing)
        await db.collection('impact_stories').deleteMany({});
        
        const result = await db.collection('impact_stories').insertMany(stories);
        console.log(`✅ Successfully seeded ${result.insertedCount} impact stories.`);

    } catch (err) {
        console.error('❌ Seeding failed:', err);
    } finally {
        await client.close();
    }
}

seedStories();
