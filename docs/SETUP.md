# DAANSETU Setup Guide

## Quick Start

### 1. Clone Repository
```bash
git clone https://github.com/phcoder05/daansetu.git
cd daansetu
```

### 2. Backend Setup
```bash
cd backend
npm install
cp .env.example .env
```

Edit `.env` with your configuration:
```env
# Required
MONGO_URI=mongodb://localhost:27017/daansetu
JWT_SECRET=your-secret-key
PORT=5000

# Optional (for NGO verification)
DARPAN_API_KEY=your-key
IT_VERIFY_API_KEY=your-key
```

Start the server:
```bash
npm run dev
```

### 3. Mobile App Setup
```bash
cd mobile
flutter pub get
cp .env.example .env
```

Edit `.env`:
```env
API_URL=http://localhost:5000/api/v1
SOCKET_URL=http://localhost:5000
```

Run the app:
```bash
flutter run
```

## Environment Variables

### Backend (api_ops/.env)

| Variable | Required | Description |
|----------|----------|-------------|
| `MONGO_URI` | ✅ | MongoDB connection string |
| `JWT_SECRET` | ✅ | Secret for JWT tokens |
| `PORT` | ❌ | Server port (default: 5000) |
| `DARPAN_API_KEY` | ❌ | NGO Darpan verification |
| `SMTP_HOST` | ❌ | Email SMTP server |

### Mobile (mobile/.env)

| Variable | Required | Description |
|----------|----------|-------------|
| `API_URL` | ✅ | Backend API URL |
| `SOCKET_URL` | ✅ | Socket.IO server URL |

## Troubleshooting

### MongoDB Connection Failed
```bash
# Check if MongoDB is running
mongosh --eval "db.runCommand('ping')"
```

### Flutter Build Errors
```bash
flutter clean
flutter pub get
flutter run
```
