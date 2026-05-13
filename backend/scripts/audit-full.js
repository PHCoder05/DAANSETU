const axios = require('axios');
const chalk = {
    green: (s) => `\x1b[32m${s}\x1b[0m`,
    red: (s) => `\x1b[31m${s}\x1b[0m`,
    yellow: (s) => `\x1b[33m${s}\x1b[0m`,
    cyan: (s) => `\x1b[36m${s}\x1b[0m`
};

const BASE_URL = 'http://localhost:5000/api/v1';

async function test(name, method, url, data = null, headers = {}) {
    try {
        process.stdout.write(`Testing ${name} (${method} ${url})... `);
        const res = await axios({
            method,
            url: `${BASE_URL}${url}`,
            data,
            headers: headers.headers || {}
        });

        if (res.data.success) {
            console.log(chalk.green('PASSED'));
            return res.data;
        } else {
            console.log(chalk.red('FAILED (Success flag false)'));
            return null;
        }
    } catch (error) {
        console.log(chalk.red(`FAILED (${error.response?.status || 'Error'})`));
        console.log(chalk.red('   -> Message:'), JSON.stringify(error.response?.data?.message || error.response?.data || error.message));
        return null;
    }
}

async function audit() {
    console.log(chalk.cyan('\n🏆 Starting Full Daansetu API Audit...\n'));

    // --- 1. AUTHENTICATION ---
    console.log(chalk.yellow('Phase 1: Authentication'));
    
    const adminLogin = await test('Admin Login', 'POST', '/auth/login', { email: 'admin@daansetu.com', password: '@Admin24' });
    const donorLogin = await test('Donor Login', 'POST', '/auth/login', { email: 'pankajhadole4@gmail.com', password: '@Pankaj24' });
    const volunteerLogin = await test('Volunteer Login', 'POST', '/auth/login', { email: 'volunteer@daansetu.com', password: '@Volunteer24' });

    if (!adminLogin || !donorLogin || !volunteerLogin) {
        console.log(chalk.red('❌ Critical login failures. Stopping audit.'));
        return;
    }

    const adminHeaders = { headers: { Authorization: `Bearer ${adminLogin.data.accessToken}` } };
    const donorHeaders = { headers: { Authorization: `Bearer ${donorLogin.data.accessToken}` } };
    const volunteerHeaders = { headers: { Authorization: `Bearer ${volunteerLogin.data.accessToken}` } };

    // --- 2. ADMIN FLOW ---
    console.log(chalk.yellow('\nPhase 2: Admin Operations'));
    await test('Admin: Get Users', 'GET', '/admin/users', null, adminHeaders);
    await test('Admin: Get Pending NGOs', 'GET', '/admin/ngos/pending', null, adminHeaders);
    await test('Admin: Get Stats', 'GET', '/admin/stats', null, adminHeaders);
    await test('Admin: Get Active Volunteers', 'GET', '/admin/volunteers/active', null, adminHeaders);

    // --- 3. AI & GEMINI ---
    console.log(chalk.yellow('\nPhase 3: AI & Gemini Integration'));
    await test('AI: Voice Search', 'POST', '/ai/voice-search', { query: 'looking for food donations in pune' }, donorHeaders);
    await test('AI: Chat', 'POST', '/ai/chat', { message: 'What is Daansetu?' }, donorHeaders);
    await test('AI: Match NGO', 'POST', '/ai/match', { category: 'food', lat: 18.5, lng: 73.8 }, donorHeaders);

    // --- 4. AUDIT & ACTIVITY ---
    console.log(chalk.yellow('\nPhase 4: Audit Logs'));
    await test('Audit: My Activity', 'GET', '/audit/my', null, donorHeaders);
    await test('Audit: Summary', 'GET', '/audit/summary', null, donorHeaders);

    // --- 5. CHAT ---
    console.log(chalk.yellow('\nPhase 5: Chat Messaging'));
    await test('Chat: Get Conversations', 'GET', '/chat/conversations', null, donorHeaders);

    // --- 6. GAMIFICATION ---
    console.log(chalk.yellow('\nPhase 6: Gamification'));
    await test('Gamification: Get Stats', 'GET', '/gamification/stats', null, donorHeaders);

    // --- 7. VOLUNTEER & INVENTORY ---
    console.log(chalk.yellow('\nPhase 7: Volunteer & Inventory'));
    await test('Volunteer: Profile', 'GET', '/auth/profile', null, volunteerHeaders);
    await test('Inventory: Get NGO Inventory', 'GET', '/ngo/inventory', null, volunteerHeaders);

    // --- 8. REPORTS ---
    console.log(chalk.yellow('\nPhase 8: Reports & Issues'));
    await test('Reports: Get All (Admin)', 'GET', '/reports', null, adminHeaders);

    // --- 9. GENERAL MODULES ---
    console.log(chalk.yellow('\nPhase 9: General Modules'));
    await test('Health: Live', 'GET', '/health/live', null, {});
    await test('Health: Ready', 'GET', '/health/ready', null, {});
    await test('Search: Categories', 'GET', '/search/categories', null, {});

    console.log(chalk.cyan('\n🏁 Full Audit Completed.\n'));
}

audit();
