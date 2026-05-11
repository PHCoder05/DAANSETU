const http = require('http');

const BASE_URL = 'http://localhost:5000/api';
const EMAIL = 'pankajhadole4@gmail.com';
const PASSWORD = '@Pankaj24';

function request(method, path, data = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json'
      }
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        try {
          const parsed = JSON.parse(body);
          resolve({ status: res.statusCode, data: parsed });
        } catch(e) {
          resolve({ status: res.statusCode, data: body });
        }
      });
    });

    req.on('error', reject);

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function testAPIs() {
  console.log(`Testing Login for ${EMAIL}...`);
  const loginRes = await request('POST', '/auth/login', { email: EMAIL, password: PASSWORD });
  
  if (loginRes.status !== 200 || !loginRes.data.data || !loginRes.data.data.accessToken) {
    console.error('Login failed:', loginRes.status, loginRes.data);
    return;
  }
  
  const token = loginRes.data.data.accessToken;
  const user = loginRes.data.data.user;
  console.log(`Login successful! Role: ${user.role}, ID: ${user._id}`);
  
  const endpointsToTest = [
    '/auth/profile',
    '/dashboard',
    `/donations?donorId=${user._id}`,
    '/donations/my',
    '/notifications',
  ];
  
  for (const endpoint of endpointsToTest) {
    console.log(`\nTesting GET ${endpoint}...`);
    try {
      const res = await request('GET', endpoint, null, token);
      console.log(`Status: ${res.status}`);
      if (res.data && res.data.success !== undefined) {
         console.log(`Success flag: ${res.data.success}`);
         if (res.data.data) {
            console.log(`Data keys: ${Object.keys(res.data.data)}`);
            if (endpoint === '/dashboard') {
               console.log('Dashboard stats:', JSON.stringify(res.data.data.stats, null, 2));
            }
            if (endpoint.startsWith('/donations?donorId')) {
               console.log('Donations list length:', res.data.data.data?.length);
               console.log('Pagination total:', res.data.data.pagination?.total);
            }
            if (endpoint === '/donations/my') {
               console.log('My donations length:', res.data.data.donations?.length);
            }
         } else {
            console.log('Response:', JSON.stringify(res.data, null, 2));
         }
      } else {
         console.log('Response:', JSON.stringify(res.data, null, 2));
      }
    } catch (e) {
      console.error(`Failed to call ${endpoint}:`, e.message);
    }
  }
}

testAPIs();
