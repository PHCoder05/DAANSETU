const axios = require('axios');
require('dotenv').config();

const API_URL = process.env.API_URL || 'http://localhost:5000/api';

async function testLeaderboard() {
    try {
        const email = 'leaderboard_test_' + Date.now() + '@daansetu.org';

        // 1. Register User
        try {
            await axios.post('http://localhost:5000/api/auth/register', {
                email,
                password: 'password123',
                name: 'Leaderboard Test',
                role: 'donor'
            });
            console.log('Registered user:', email);
        } catch (e) {
            // Ignore if exists
        }

        // 2. Generate token
        const tokenRes = await axios.post('http://localhost:5000/api/auth/generate-token', {
            email
        });
        const token = tokenRes.data.data.accessToken;
        console.log('Got token');

        // 3. Fetch Leaderboard
        const res = await axios.get('http://localhost:5000/api/auth/leaderboard', {
            headers: { Authorization: `Bearer ${token}` }
        });

        console.log('Leaderboard Count:', res.data.data.leaderboard.length);
        console.log('Leaderboard Data:', JSON.stringify(res.data.data.leaderboard, null, 2));

    } catch (error) {
        console.error('Error:', error.response ? JSON.stringify(error.response.data) : error.message);
    }
}

testLeaderboard();
