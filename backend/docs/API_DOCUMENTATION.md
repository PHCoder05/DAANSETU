# DAANSETU API Documentation

## Base URL
```
http://localhost:3000/api
```

## Authentication

Most endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

---

## 🔐 Authentication Endpoints

### 1. Register User

**Endpoint:** `POST /auth/register`

**Description:** Register a new user (donor or NGO)

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "role": "donor",  // "donor" or "ngo"
  "phone": "+1234567890",
  "address": "123 Main St, New York, NY",
  "location": {
    "lat": 40.7128,
    "lng": -74.0060,
    "address": "New York, NY"
  },
  // For NGO role only:
  "ngoDetails": {
    "registrationNumber": "NGO12345",
    "description": "NGO description",
    "website": "https://ngo.org",
    "categories": ["food", "clothes"],
    "establishedYear": 2020
  }
}
```

**Response:** `201 Created`
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 2. Login

**Endpoint:** `POST /auth/login`

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": { ... },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 3. Get Profile

**Endpoint:** `GET /auth/profile`

**Auth:** Required

**Response:** `200 OK`

### 4. Update Profile

**Endpoint:** `PUT /auth/profile`

**Auth:** Required

**Request Body:**
```json
{
  "name": "John Updated",
  "phone": "+1234567890",
  "address": "New address",
  "location": { ... }
}
```

### 5. Change Password

**Endpoint:** `PUT /auth/change-password`

**Auth:** Required

**Request Body:**
```json
{
  "currentPassword": "oldpassword",
  "newPassword": "newpassword123"
}
```

### 6. Update NGO Details

**Endpoint:** `PUT /auth/ngo-details`

**Auth:** Required (NGO only)

**Request Body:**
```json
{
  "ngoDetails": {
    "description": "Updated description",
    "website": "https://ngo.org",
    "categories": ["food", "medical"]
  }
}
```

---

## 📦 Donation Endpoints

### 1. Get All Donations

**Endpoint:** `GET /donations`

**Auth:** Optional

**Query Parameters:**
- `page` (integer): Page number (default: 1)
- `limit` (integer): Items per page (default: 10, max: 100)
- `category` (string): Filter by category
- `status` (string): Filter by status
- `priority` (string): Filter by priority
- `search` (string): Search in title/description

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Donations retrieved successfully",
  "data": {
    "data": [ ... ],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 50,
      "totalPages": 5,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

### 2. Get Donation by ID

**Endpoint:** `GET /donations/:id`

**Auth:** Optional

**Response:** `200 OK`

### 3. Create Donation

**Endpoint:** `POST /donations`

**Auth:** Required (Donor only)

**Request Body:**
```json
{
  "title": "Fresh Vegetables",
  "description": "Organic vegetables from local farm",
  "category": "food",
  "quantity": 50,
  "unit": "kg",
  "condition": "new",
  "expiryDate": "2025-12-31",
  "pickupLocation": {
    "lat": 40.7128,
    "lng": -74.0060,
    "address": "123 Main St, New York, NY"
  },
  "pickupInstructions": "Ring doorbell",
  "priority": "high",
  "tags": ["organic", "fresh"],
  "images": ["url1", "url2"]
}
```

**Categories:** `food`, `clothes`, `books`, `medical`, `electronics`, `furniture`, `other`

**Condition:** `new`, `good`, `fair`, `used`

**Priority:** `low`, `normal`, `high`, `urgent`

**Response:** `201 Created`

### 4. Update Donation

**Endpoint:** `PUT /donations/:id`

**Auth:** Required (Owner only)

**Request Body:** (All fields optional)
```json
{
  "title": "Updated title",
  "description": "Updated description",
  "quantity": 60,
  ...
}
```

### 5. Delete Donation

**Endpoint:** `DELETE /donations/:id`

**Auth:** Required (Owner only)

**Response:** `200 OK`

### 6. Claim Donation

**Endpoint:** `POST /donations/:id/claim`

**Auth:** Required (Verified NGO only)

**Description:** Claim an available donation

**Response:** `200 OK`

### 7. Update Donation Status

**Endpoint:** `PUT /donations/:id/status`

**Auth:** Required

**Request Body:**
```json
{
  "status": "in-transit",
  "deliveryNotes": "Package picked up",
  "deliveryImages": ["url1"]
}
```

**Valid Status Transitions:**
- `available` → `claimed`, `cancelled`
- `claimed` → `in-transit`, `available`, `cancelled`
- `in-transit` → `delivered`, `claimed`

### 8. Get Nearby Donations

**Endpoint:** `GET /donations/nearby`

**Auth:** Optional

**Query Parameters:**
- `lat` (float): Latitude
- `lng` (float): Longitude
- `maxDistance` (float): Maximum distance in km (default: 50)

### 9. Get Donation Statistics

**Endpoint:** `GET /donations/stats/summary`

**Auth:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "statusStats": [ ... ],
    "categoryStats": [ ... ]
  }
}
```

---

## 🏢 NGO Endpoints

### 1. Get All NGOs

**Endpoint:** `GET /ngos`

**Auth:** Optional

**Query Parameters:**
- `page`, `limit`: Pagination
- `search`: Search NGO name/description
- `category`: Filter by work category

**Response:** `200 OK`

### 2. Get NGO by ID

**Endpoint:** `GET /ngos/:id`

**Auth:** Optional

**Response:** `200 OK`

### 3. Create Request

**Endpoint:** `POST /ngos/requests`

**Auth:** Required (Verified NGO only)

**Description:** Request a specific donation

**Request Body:**
```json
{
  "donationId": "donation_id_here",
  "message": "We need this for 50 families",
  "beneficiariesCount": 50,
  "needByDate": "2025-10-20",
  "priority": "high"
}
```

**Response:** `201 Created`

### 4. Get Requests

**Endpoint:** `GET /ngos/requests/list`

**Auth:** Required

**Description:** 
- NGOs see their own requests
- Donors see requests for their donations

**Query Parameters:**
- `page`, `limit`: Pagination
- `status`: Filter by status

**Response:** `200 OK`

### 5. Update Request Status

**Endpoint:** `PUT /ngos/requests/:id/status`

**Auth:** Required (Donor only)

**Description:** Approve or reject a request

**Request Body:**
```json
{
  "status": "approved",  // "approved" or "rejected"
  "response": "Optional message to NGO"
}
```

### 6. Cancel Request

**Endpoint:** `PUT /ngos/requests/:id/cancel`

**Auth:** Required (NGO only)

**Description:** Cancel own pending request

**Response:** `200 OK`

---

## 🔔 Notification Endpoints

### 1. Get Notifications

**Endpoint:** `GET /notifications`

**Auth:** Required

**Query Parameters:**
- `page`, `limit`: Pagination
- `unreadOnly`: Filter unread (true/false)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "data": [ ... ],
    "pagination": { ... },
    "unreadCount": 5
  }
}
```

### 2. Get Unread Count

**Endpoint:** `GET /notifications/unread-count`

**Auth:** Required

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "count": 5
  }
}
```

### 3. Mark as Read

**Endpoint:** `PUT /notifications/:id/read`

**Auth:** Required

**Response:** `200 OK`

### 4. Mark All as Read

**Endpoint:** `PUT /notifications/read-all`

**Auth:** Required

**Response:** `200 OK`

### 5. Delete Notification

**Endpoint:** `DELETE /notifications/:id`

**Auth:** Required

**Response:** `200 OK`

---

## 👑 Admin Endpoints

All admin endpoints require admin role.

### 1. Get All Users

**Endpoint:** `GET /admin/users`

**Auth:** Required (Admin)

**Query Parameters:**
- `page`, `limit`: Pagination
- `role`: Filter by role
- `verified`: Filter by verification status
- `active`: Filter by active status

### 2. Delete User

**Endpoint:** `DELETE /admin/users/:userId`

**Auth:** Required (Admin)

### 3. Toggle User Status

**Endpoint:** `PUT /admin/users/:userId/toggle-status`

**Auth:** Required (Admin)

**Description:** Activate/deactivate user

### 4. Get Pending NGOs

**Endpoint:** `GET /admin/ngos/pending`

**Auth:** Required (Admin)

**Description:** Get NGOs pending verification

### 5. Verify NGO

**Endpoint:** `PUT /admin/ngos/:userId/verify`

**Auth:** Required (Admin)

**Request Body:**
```json
{
  "status": "verified",  // "verified" or "rejected"
  "reason": "Optional reason for rejection"
}
```

### 6. Get Platform Statistics

**Endpoint:** `GET /admin/stats`

**Auth:** Required (Admin)

**Response:** `200 OK`
```json
{
  "success": true,
  "data": {
    "users": {
      "total": 1000,
      "donors": 600,
      "ngos": 380,
      "verifiedNGOs": 350,
      "pendingNGOs": 30
    },
    "donations": {
      "total": 5000,
      "available": 1000,
      "claimed": 2000,
      "delivered": 1800,
      "byCategory": [ ... ]
    },
    "recentActivity": { ... }
  }
}
```

### 7. Seed Database (Development Only)

**Endpoint:** `POST /admin/seed`

**Auth:** Required (Admin, Development only)

**Description:** Create test data

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Test data seeded successfully",
  "data": {
    "donor": {
      "email": "donor@test.com",
      "password": "password123"
    },
    "ngo": {
      "email": "ngo@test.com",
      "password": "password123"
    }
  }
}
```

---

## 📋 Common Response Codes

- `200 OK`: Successful GET, PUT, DELETE
- `201 Created`: Successful POST
- `400 Bad Request`: Validation error
- `401 Unauthorized`: Authentication required or invalid
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

## 🔄 Pagination

All list endpoints support pagination with consistent format:

**Query Parameters:**
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)

**Response Format:**
```json
{
  "data": [ ... ],
  "pagination": {
    "page": 1,
    "limit": 10,
    "total": 50,
    "totalPages": 5,
    "hasNext": true,
    "hasPrev": false
  }
}
```

---

## 🎯 Best Practices

1. **Always include Authorization header** for protected routes
2. **Handle pagination** for list endpoints
3. **Validate input** on client side before sending
4. **Check error responses** and display appropriate messages
5. **Use appropriate status codes** for error handling
6. **Implement retry logic** for failed requests
7. **Cache static data** like NGO lists when appropriate

---

For more information, visit the [GitHub Repository](https://github.com/yourusername/daansetu-backend)

