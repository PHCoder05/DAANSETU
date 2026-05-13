const axios = require('axios');
const chalk = {
    green: (s) => `\x1b[32m${s}\x1b[0m`,
    red: (s) => `\x1b[31m${s}\x1b[0m`,
    yellow: (s) => `\x1b[33m${s}\x1b[0m`,
    cyan: (s) => `\x1b[36m${s}\x1b[0m`,
    bold: (s) => `\x1b[1m${s}\x1b[22m${s}`
};

const BASE_URL = 'http://localhost:5000/api/v1';

async function audit() {
    console.log(chalk.cyan('\n🚀 Starting Daansetu API Audit...\n'));

    let donorToken = '';
    let donorId = '';
    
    // 1. LOGIN
    try {
        console.log(chalk.yellow('Step 1: Logging in as Donor...'));
        const loginRes = await axios.post(`${BASE_URL}/auth/login`, {
            email: 'pankajhadole4@gmail.com',
            password: '@Pankaj24'
        });
        
        donorToken = loginRes.data.data.accessToken;
        donorId = loginRes.data.data.user._id;
        console.log(chalk.green(`✅ Login successful. Donor ID: ${donorId}`));
    } catch (error) {
        console.error(chalk.red('❌ Login failed:'), error.response?.data || error.message);
        return;
    }

    const authHeaders = { headers: { Authorization: `Bearer ${donorToken}` } };

    const tests = [
        { name: 'GET Auth Profile', url: '/auth/profile', method: 'GET', headers: authHeaders },
        { name: 'GET Leaderboard', url: '/auth/leaderboard', method: 'GET' },
        { name: 'GET All Donations', url: '/donations', method: 'GET' },
        { name: 'GET My Donations', url: '/donations/my', method: 'GET', headers: authHeaders },
        { name: 'GET Nearby Donations', url: '/donations/nearby?lat=18.623&lng=73.748', method: 'GET' },
        { name: 'GET Donation Stats', url: '/donations/stats/summary', method: 'GET', headers: authHeaders },
        { name: 'GET NGOs List', url: '/ngos', method: 'GET' },
        { name: 'GET NGO Requests', url: '/ngos/requests/list', method: 'GET', headers: authHeaders },
        { name: 'GET Notifications', url: '/notifications', method: 'GET', headers: authHeaders },
        { name: 'GET Dashboard', url: '/dashboard', method: 'GET', headers: authHeaders },
        { name: 'GET Search Donations', url: '/search/donations?q=food', method: 'GET' },
        { name: 'GET Search NGOs', url: '/search/ngos?q=pune', method: 'GET' },
        { name: 'GET Categories', url: '/search/categories', method: 'GET' },
        { name: 'GET Health Check', url: '/health', method: 'GET' }
    ];

    let passed = 0;
    let failed = 0;

    for (const test of tests) {
        try {
            process.stdout.write(`Testing ${test.name}... `);
            const res = await axios({
                method: test.method,
                url: `${BASE_URL}${test.url}`,
                headers: test.headers?.headers || {}
            });

            if (res.data.success) {
                // Specific logic check for "My Donations"
                if (test.url === '/donations/my') {
                    const count = res.data.data.donations?.length || 0;
                    if (count === 0) {
                        console.log(chalk.yellow(`WARN (0 results found, check if this is expected)`));
                    } else {
                        console.log(chalk.green(`PASSED (${count} items found)`));
                    }
                } else {
                    console.log(chalk.green('PASSED'));
                }
                passed++;
            } else {
                console.log(chalk.red('FAILED (Success flag false)'));
                failed++;
            }
        } catch (error) {
            console.log(chalk.red(`FAILED (${error.response?.status || 'Error'})`));
            console.log(chalk.red('   -> Message:'), error.response?.data?.message || error.message);
            failed++;
        }
    }

    console.log(chalk.cyan('\n--- Audit Summary ---'));
    console.log(chalk.green(`✅ Passed: ${passed}`));
    console.log(chalk.red(`❌ Failed: ${failed}`));
    console.log(chalk.cyan('----------------------\n'));
}

audit();
