const { sendEmail } = require('./utils/emailService');

async function test() {
    try {
        console.log('Testing sendEmail...');
        const url = await sendEmail('pankajhadole4@gmail.com', 'Password Reset Request', '<h1>Password Reset</h1><p>This is a test email triggered by the agent.</p>');
        console.log('Result URL:', url);
        const fs = require('fs');
        fs.writeFileSync('temp_url_service.txt', url);
    } catch (e) {
        console.error('Error:', e);
    }
}

test();
