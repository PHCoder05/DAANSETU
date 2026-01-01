# DAANSETU API Documentation

Base URL: `http://localhost:5000/api/v1`

## Authentication

### Register
```http
POST /auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword",
  "role": "donor"
}
```

### Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "securepassword"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGci...",
  "user": { "id": "...", "name": "John Doe" }
}
```

## Donations

### Create Donation
```http
POST /donations
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Fresh Vegetables",
  "description": "Leftover from event",
  "category": "vegetables",
  "quantity": 10,
  "unit": "kg",
  "expiryDate": "2024-01-15T18:00:00Z",
  "pickupLocation": {
    "address": "123 Main St",
    "coordinates": [77.123, 28.456]
  }
}
```

### Get All Donations
```http
GET /donations?status=available&category=vegetables
Authorization: Bearer <token>
```

### Claim Donation (NGO)
```http
POST /donations/:id/claim
Authorization: Bearer <token>
```

## Verification

### Request Verification
```http
POST /verification/request
Authorization: Bearer <token>
Content-Type: application/json

{
  "type": "ngo_registration",
  "darpanId": "MH/2024/123456",
  "pan": "ABCDE1234F"
}
```

### Get Verification Steps
```http
GET /verification/steps?type=ngo_registration
Authorization: Bearer <token>
```

## Delivery Tracking

### Initialize Tracking
```http
POST /delivery/:donationId/initialize
Authorization: Bearer <token>
```

### Update Location
```http
POST /delivery/:donationId/location
Authorization: Bearer <token>
Content-Type: application/json

{
  "lat": 28.456,
  "lng": 77.123
}
```

### Mark Delivered
```http
POST /delivery/:donationId/deliver
Authorization: Bearer <token>
Content-Type: application/json

{
  "photo": "base64...",
  "signature": "base64..."
}
```

## Error Responses

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error (dev only)"
}
```

| Status | Meaning |
|--------|---------|
| 400 | Bad Request |
| 401 | Unauthorized |
| 403 | Forbidden |
| 404 | Not Found |
| 500 | Server Error |
