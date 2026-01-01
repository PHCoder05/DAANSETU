# 🔐 Token Authentication Guide

## Overview

DAANSETU uses a **dual-token authentication system** with:
- **Access Tokens** (short-lived, 15 minutes)
- **Refresh Tokens** (long-lived, 7 days)

This provides both security and user convenience.

---

## 🎯 Authentication Flow

### 1. Registration / Login

When a user registers or logs in, they receive **both tokens**:

**Request:**
```bash
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { ... },
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresIn": "15m"
  }
}
```

**Store these tokens securely:**
- Access Token: In memory or secure cookie
- Refresh Token: In secure HTTP-only cookie or secure storage

### 2. Making Authenticated Requests

Use the **access token** in the Authorization header:

```bash
GET /api/auth/profile
Authorization: Bearer <accessToken>
```

### 3. Token Refresh (When Access Token Expires)

When the access token expires (after 15 minutes), use the refresh token to get a new pair:

**Request:**
```bash
POST /api/auth/refresh
Content-Type: application/json

{
  "refreshToken": "your-refresh-token-here"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Token refreshed successfully",
  "data": {
    "accessToken": "new-access-token",
    "refreshToken": "new-refresh-token",
    "expiresIn": "15m"
  }
}
```

**Token Rotation:** For security, both tokens are refreshed. The old refresh token is invalidated.

### 4. Logout

**Single Device Logout:**
```bash
POST /api/auth/logout
Content-Type: application/json

{
  "refreshToken": "your-refresh-token"
}
```

**All Devices Logout:**
```bash
POST /api/auth/logout-all
Authorization: Bearer <accessToken>
```

---

## 🔒 Security Features

### 1. Token Storage in Database
- Refresh tokens are stored in MongoDB with metadata
- Allows tracking of active sessions
- Enables revocation and security audits

### 2. Token Rotation
- Old refresh tokens are invalidated when used
- Reduces risk of token theft
- Prevents replay attacks

### 3. Token Revocation
- Tokens can be revoked on logout
- All user tokens can be revoked at once
- Deactivated users' tokens are invalid

### 4. Automatic Cleanup
- Expired tokens are automatically removed
- Old revoked tokens are cleaned up periodically

---

## 🛠️ Implementation in Frontend

### React Example with Axios

```javascript
import axios from 'axios';

// Setup axios interceptor for automatic token refresh
const api = axios.create({
  baseURL: 'http://localhost:3000/api'
});

let accessToken = localStorage.getItem('accessToken');
let refreshToken = localStorage.getItem('refreshToken');

// Add access token to requests
api.interceptors.request.use(
  (config) => {
    if (accessToken) {
      config.headers.Authorization = `Bearer ${accessToken}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Handle token refresh on 401 errors
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    // If error is 401 and we haven't retried yet
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;

      try {
        // Refresh the token
        const response = await axios.post(
          'http://localhost:3000/api/auth/refresh',
          { refreshToken }
        );

        const { accessToken: newAccessToken, refreshToken: newRefreshToken } = response.data.data;

        // Update tokens
        accessToken = newAccessToken;
        refreshToken = newRefreshToken;
        localStorage.setItem('accessToken', newAccessToken);
        localStorage.setItem('refreshToken', newRefreshToken);

        // Retry original request with new token
        originalRequest.headers.Authorization = `Bearer ${newAccessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        // Refresh failed, logout user
        localStorage.removeItem('accessToken');
        localStorage.removeItem('refreshToken');
        window.location.href = '/login';
        return Promise.reject(refreshError);
      }
    }

    return Promise.reject(error);
  }
);

export default api;
```

### Usage
```javascript
// Login
const login = async (email, password) => {
  const response = await api.post('/auth/login', { email, password });
  const { accessToken, refreshToken } = response.data.data;
  
  localStorage.setItem('accessToken', accessToken);
  localStorage.setItem('refreshToken', refreshToken);
  
  return response.data;
};

// Logout
const logout = async () => {
  const refreshToken = localStorage.getItem('refreshToken');
  await api.post('/auth/logout', { refreshToken });
  
  localStorage.removeItem('accessToken');
  localStorage.removeItem('refreshToken');
};

// Make authenticated request (automatic token refresh)
const getProfile = async () => {
  const response = await api.get('/auth/profile');
  return response.data;
};
```

---

## ⚙️ Environment Variables

Add these to your `.env` file:

```env
# Access Token (short-lived)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=15m

# Refresh Token (long-lived)
JWT_REFRESH_SECRET=your-super-secret-refresh-key-change-this-in-production
JWT_REFRESH_EXPIRES_IN=7d
```

**Security Best Practices:**
- Use different secrets for access and refresh tokens
- Use long, random strings (64+ characters)
- Never commit secrets to version control
- Rotate secrets periodically

---

## 📊 Token Lifecycle

```
User Login
    ↓
Receive Access Token (15m) + Refresh Token (7d)
    ↓
Store Tokens Securely
    ↓
Make API Requests with Access Token
    ↓
Access Token Expires (after 15m)
    ↓
Use Refresh Token to Get New Pair
    ↓
Receive New Access Token + New Refresh Token
    ↓
Old Refresh Token Invalidated
    ↓
Continue Making API Requests
    ↓
User Logout → All Tokens Invalidated
```

---

## 🧪 Testing with Postman

### 1. Setup Environment Variables

In Postman, create these variables:
- `baseUrl`: `http://localhost:3000/api`
- `accessToken`: (empty initially)
- `refreshToken`: (empty initially)

### 2. Login Request

Create a login request and add this script to **Tests** tab:

```javascript
// Save tokens from response
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.environment.set('accessToken', response.data.accessToken);
    pm.environment.set('refreshToken', response.data.refreshToken);
}
```

### 3. Authenticated Requests

Add to Authorization tab:
- Type: Bearer Token
- Token: `{{accessToken}}`

### 4. Refresh Token Request

Create a refresh request with this body:
```json
{
  "refreshToken": "{{refreshToken}}"
}
```

Add to Tests tab:
```javascript
// Update tokens
if (pm.response.code === 200) {
    const response = pm.response.json();
    pm.environment.set('accessToken', response.data.accessToken);
    pm.environment.set('refreshToken', response.data.refreshToken);
}
```

---

## 🚨 Error Handling

### Common Errors

**401 Unauthorized - Access Token Expired:**
```json
{
  "success": false,
  "message": "Token has expired."
}
```
**Action:** Use refresh token to get new access token

**401 Unauthorized - Invalid Refresh Token:**
```json
{
  "success": false,
  "message": "Invalid or expired refresh token"
}
```
**Action:** User must login again

**401 Unauthorized - Token Revoked:**
```json
{
  "success": false,
  "message": "Refresh token not found or has been revoked"
}
```
**Action:** User must login again

---

## 🎯 Best Practices

### For Frontend Developers

1. **Store Tokens Securely**
   - Never store in localStorage (XSS vulnerable)
   - Use secure HTTP-only cookies when possible
   - Or use memory + secure storage

2. **Implement Auto-Refresh**
   - Use interceptors to refresh tokens automatically
   - Don't wait for 401 - refresh proactively before expiry

3. **Handle Token Expiry Gracefully**
   - Show login prompt when refresh fails
   - Preserve user's intended action
   - Clear user state on logout

4. **Never Log Tokens**
   - Don't console.log tokens
   - Don't send tokens in error reports
   - Redact tokens in logs

### For Backend Developers

1. **Rotate Tokens on Refresh**
   - Invalidate old refresh token
   - Issue new pair
   - Detect token reuse attacks

2. **Clean Up Old Tokens**
   - Schedule cleanup job
   - Remove expired tokens
   - Remove revoked tokens older than 30 days

3. **Monitor Token Usage**
   - Track active sessions
   - Alert on suspicious activity
   - Implement rate limiting

4. **Secure Token Storage**
   - Index tokens for fast lookup
   - Store token hash (optional)
   - Include user agent for validation

---

## 📖 API Endpoints Summary

| Endpoint | Method | Description | Auth Required |
|----------|--------|-------------|---------------|
| `/api/auth/register` | POST | Register & get tokens | No |
| `/api/auth/login` | POST | Login & get tokens | No |
| `/api/auth/refresh` | POST | Refresh access token | No (refresh token in body) |
| `/api/auth/logout` | POST | Logout (revoke token) | No (refresh token in body) |
| `/api/auth/logout-all` | POST | Logout from all devices | Yes |

---

## ✅ Checklist

**Frontend Implementation:**
- [ ] Store tokens securely
- [ ] Add Authorization header to requests
- [ ] Implement automatic token refresh
- [ ] Handle token expiry errors
- [ ] Implement logout functionality
- [ ] Clear tokens on error

**Backend Verification:**
- [ ] Tokens are issued correctly
- [ ] Access token expires after 15m
- [ ] Refresh token expires after 7d
- [ ] Token rotation works
- [ ] Logout revokes tokens
- [ ] Old tokens are cleaned up

**Security:**
- [ ] Different secrets for access/refresh
- [ ] Secrets are random and long
- [ ] Secrets not in version control
- [ ] HTTPS in production
- [ ] Secure token storage
- [ ] Rate limiting on auth endpoints

---

**Ready to implement secure authentication! 🔐**

