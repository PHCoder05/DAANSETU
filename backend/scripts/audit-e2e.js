const axios = require('axios');
const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config();

const chalk = {
    green: (s) => `\x1b[32m${s}\x1b[0m`,
    red: (s) => `\x1b[31m${s}\x1b[0m`,
    yellow: (s) => `\x1b[33m${s}\x1b[0m`,
    cyan: (s) => `\x1b[36m${s}\x1b[0m`
};

const BASE_URL = 'http://localhost:5000/api/v1';
const MONGODB_URI = process.env.MONGODB_URI;
const DB_NAME = process.env.DB_NAME || 'daansetu';

async function audit() {
    console.log(chalk.cyan('\n🏁 Starting End-to-End API Audit...\n'));

    const client = new MongoClient(MONGODB_URI);
    await client.connect();
    const db = client.db(DB_NAME);

    const testNgoEmail = 'testngo@example.com';
    const testNgoPassword = '@TestNGO24';
    let ngoToken = '';
    let ngoId = '';

    try {
        console.log(chalk.yellow('Step 1: Authenticating NGO...'));
        try {
            const ngoLoginRes = await axios.post(`${BASE_URL}/auth/login`, {
                email: testNgoEmail,
                password: testNgoPassword
            });
            ngoToken = ngoLoginRes.data.data.accessToken;
            ngoId = ngoLoginRes.data.data.user._id;
            console.log(chalk.green(`✅ NGO Logged in: ${ngoId}`));
        } catch (e) {
            console.log(chalk.cyan('NGO not found, registering...'));
            const registerRes = await axios.post(`${BASE_URL}/auth/register`, {
                email: testNgoEmail,
                password: testNgoPassword,
                name: 'Test NGO Pune',
                role: 'ngo',
                phone: '9876543210',
                location: { lat: 18.52, lng: 73.85, address: 'Pune Central' }
            });
            ngoId = registerRes.data.data.user._id;
            ngoToken = registerRes.data.data.accessToken;
            console.log(chalk.green(`✅ NGO Registered: ${ngoId}`));
        }
        
        // Manually verify NGO in DB
        await db.collection('users').updateOne(
            { _id: new ObjectId(ngoId) },
            { $set: { verified: true, 'ngoDetails.verificationStatus': 'verified' } }
        );
        console.log(chalk.green(`✅ NGO Verified in DB`));

        // --- 2. LOGIN DONOR ---
        console.log(chalk.yellow('\nStep 2: Authenticating Donor...'));
        const donorRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'pankajhadole4@gmail.com',
            password: '@Pankaj24'
        });
        const donorToken = donorRes.data.data.accessToken;
        const donorId = donorRes.data.data.user._id;

        console.log(chalk.green('✅ Donor authentication token obtained.'));

        // --- 3. DONOR: CREATE DONATION ---
        console.log(chalk.yellow('\nStep 3: Donor creating donation...'));
        const donationRes = await axios.post(`${BASE_URL}/donations`, {
            title: 'Audit Test Donation',
            description: 'Testing end-to-end flow',
            category: 'food',
            quantity: 10,
            unit: 'kg',
            pickupLocation: { lat: 18.5, lng: 73.8, address: 'Test Street 1' }
        }, { headers: { Authorization: `Bearer ${donorToken}` } });

        const donationId = donationRes.data.data.donation._id;
        console.log(chalk.green(`✅ Donation Created: ${donationId}`));

        // --- 4. NGO: REQUEST DONATION ---
        console.log(chalk.yellow('\nStep 4: NGO requesting donation...'));
        const requestRes = await axios.post(`${BASE_URL}/ngos/requests`, {
            donationId: donationId,
            message: 'We need this for our shelter',
            beneficiariesCount: 20
        }, { headers: { Authorization: `Bearer ${ngoToken}` } });

        const requestId = requestRes.data.data.request._id;
        console.log(chalk.green(`✅ Request Created: ${requestId}`));

        // --- 5. DONOR: APPROVE REQUEST ---
        console.log(chalk.yellow('\nStep 5: Donor approving request...'));
        await axios.put(`${BASE_URL}/ngos/requests/${requestId}/status`, {
            status: 'approved',
            response: 'Sure, please pick it up!'
        }, { headers: { Authorization: `Bearer ${donorToken}` } });
        console.log(chalk.green('✅ Request Approved. Donation is now CLAIMED.'));

        // --- 6. NGO: INITIALIZE DELIVERY ---
        console.log(chalk.yellow('\nStep 6: NGO initializing tracking...'));
        await axios.post(`${BASE_URL}/delivery/${donationId}/initialize`, {
            scheduledPickupTime: new Date(Date.now() + 3600000)
        }, { headers: { Authorization: `Bearer ${ngoToken}` } });
        console.log(chalk.green('✅ Tracking Initialized.'));

        // --- 7. NGO: PICKUP & DELIVER ---
        console.log(chalk.yellow('\nStep 7: NGO updating delivery status...'));
        
        // Fetch pickup QR code as Donor
        const donorTrackingRes = await axios.get(`${BASE_URL}/delivery/${donationId}`, {
            headers: { Authorization: `Bearer ${donorToken}` }
        });
        const pickupQr = donorTrackingRes.data.data.tracking.pickupQrCode;

        // Fetch delivery QR code as NGO
        const ngoTrackingRes = await axios.get(`${BASE_URL}/delivery/${donationId}`, {
            headers: { Authorization: `Bearer ${ngoToken}` }
        });
        const deliveryQr = ngoTrackingRes.data.data.tracking.deliveryQrCode;

        console.log(chalk.cyan(`   QR codes obtained: Pickup=${pickupQr}, Delivery=${deliveryQr}`));

        await axios.post(`${BASE_URL}/delivery/${donationId}/pickup`, {
            location: { lat: 18.5, lng: 73.8 },
            qrCode: pickupQr
        }, { headers: { Authorization: `Bearer ${ngoToken}` } });
        console.log(chalk.green('✅ Marked as PICKED UP.'));

        await axios.post(`${BASE_URL}/delivery/${donationId}/deliver`, {
            location: { lat: 18.52, lng: 73.82 },
            qrCode: deliveryQr
        }, { headers: { Authorization: `Bearer ${ngoToken}` } });
        console.log(chalk.green('✅ Marked as DELIVERED.'));

        // --- 8. DONOR: CONFIRM ---
        console.log(chalk.yellow('\nStep 8: Donor confirming delivery...'));
        await axios.post(`${BASE_URL}/delivery/${donationId}/confirm`, {}, { 
            headers: { Authorization: `Bearer ${donorToken}` } 
        });
        console.log(chalk.green('✅ Delivery CONFIRMED by Donor.'));

        // --- 9. CLEANUP ---
        console.log(chalk.yellow('\nStep 9: Cleaning up test data...'));
        await db.collection('donations').deleteOne({ _id: new ObjectId(donationId) });
        await db.collection('requests').deleteOne({ _id: new ObjectId(requestId) });
        await db.collection('delivery_tracking').deleteOne({ donationId: new ObjectId(donationId) });
        await db.collection('users').deleteOne({ _id: new ObjectId(ngoId) });
        console.log(chalk.green('✅ Cleanup completed.'));

        console.log(chalk.cyan('\n🏆 End-to-End Audit PASSED successfully!\n'));

    } catch (error) {
        console.error(chalk.red('\n❌ E2E Audit FAILED:'));
        if (error.response) {
            console.error(chalk.red(`   Status: ${error.response.status}`));
            console.error(chalk.red('   Data:'), JSON.stringify(error.response.data, null, 2));
        } else {
            console.error(chalk.red(`   Message: ${error.message}`));
        }
    } finally {
        await client.close();
    }
}

audit();
