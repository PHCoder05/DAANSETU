const http = require('http');
const fs = require('fs');

const data = JSON.stringify({
    email: 'pankajhadole4@gmail.com'
});

const options = {
    hostname: 'localhost',
    port: 5000,
    path: '/api/password-reset/request',
    method: 'POST',
    headers: {
        'Content-Type': 'application/json',
        'Content-Length': data.length
    }
};

console.log('🚀 Sending Password Reset Request...');

const req = http.request(options, (res) => {
    console.log(`✅ Status Code: ${res.statusCode}`);

    let body = '';
    res.on('data', (chunk) => body += chunk);
    res.on('end', () => {
        try {
            const parsed = JSON.parse(body);
            // console.log('✅ Response:', JSON.stringify(parsed, null, 2));
            if (parsed.data && parsed.data.previewUrl) {
                console.log('PREVIEW_URL:' + parsed.data.previewUrl);
                fs.writeFileSync('temp_url.txt', parsed.data.previewUrl);
                console.log('URL written to temp_url.txt');
            } else {
                console.log('No preview URL found');
            }
        } catch (e) {
            console.log('Error parsing response');
        }
    });
});

req.on('error', (error) => {
    console.log('ERROR');
});

req.write(data);
req.end();
