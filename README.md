# 🌉 DAANSETU - Multi-Category Donation Platform

<p align="center">
  <img src="docs/assets/logo.png" alt="DAANSETU Logo" width="200"/>
</p>

<p align="center">
  <strong>Bridge of Giving - Connecting Donors with Verified NGOs</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#demo">Demo</a> •
  <a href="#installation">Installation</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"/>
  <img src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg" alt="PRs Welcome"/>
  <img src="https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web-lightgrey.svg" alt="Platform"/>
</p>

<p align="center">
  <a href="https://github.com/phcoder05/daansetu/actions/workflows/backend-ci.yml"><img src="https://github.com/phcoder05/daansetu/actions/workflows/backend-ci.yml/badge.svg" alt="Backend CI"></a>
  <a href="https://github.com/phcoder05/daansetu/actions/workflows/mobile-ci.yml"><img src="https://github.com/phcoder05/daansetu/actions/workflows/mobile-ci.yml/badge.svg" alt="Mobile CI"></a>
</p>

---

## 🌟 What is DAANSETU?

**DAANSETU** ("Bridge of Giving" in Hindi) is a comprehensive open-source donation platform that connects donors with government-verified NGOs. Unlike single-purpose apps, DAANSETU supports **multiple donation categories** with complete transparency and real-time tracking.

### 📦 Supported Donation Categories

| Category | Examples |
|----------|----------|
| 🍎 **Food** | Meals, groceries, packaged food |
| 👕 **Clothes** | Garments, footwear, accessories |
| 📚 **Books** | Textbooks, novels, educational material |
| 💊 **Medical** | Medicines, equipment, first aid |
| 💻 **Electronics** | Phones, laptops, appliances |
| 🪑 **Furniture** | Tables, chairs, beds |
| 📦 **Other** | Any other useful items |

### The Problem
- **Donors** don't know if their donations reach the right people
- **NGOs** struggle to find reliable, consistent donors
- **No transparency** in the donation-to-delivery process
- **Fake NGOs** exploit the goodwill of donors

### Our Solution
A transparent, verified platform with:
- ✅ **Government API verification** (NGO Darpan, 80G, MCA)
- 📍 **Real-time GPS tracking** from pickup to delivery
- 📸 **Photo proof** at every step
- 🔐 **Complete audit trail** of every action
- ⭐ **Reviews & ratings** for accountability

---

## ✨ Features

### For Donors
- 📱 List **any type of donation** with photos
- 🏢 Only **verified NGOs** can claim
- 📊 Track your donation journey in real-time
- ⭐ Review NGOs after delivery
- 📜 Full history of all your donations

### For NGOs
- 🔔 Instant notifications for nearby donations
- 📍 GPS navigation to pickup location
- ✅ QR code verification system
- 📈 Analytics dashboard
- 💬 In-app chat with donors

### For Admins
- 🛡️ **Two-step NGO verification**
  - Step 1: Government API auto-check
  - Step 2: Manual review
- 🔄 Bypass option with audit trail
- 🚨 Fraud detection alerts
- 📝 Complete activity logs
- 📊 Platform-wide analytics

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| **Mobile App** | Flutter (iOS + Android) |
| **Backend API** | Node.js + Express.js |
| **Database** | MongoDB |
| **Real-time** | Socket.IO |
| **Auth** | JWT + bcrypt |
| **Verification** | NGO Darpan, 80G, MCA APIs |
| **Infrastructure** | Docker, Terraform, AWS |
| **CI/CD** | Jenkins |

---

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- MongoDB
- Flutter 3.0+

### Backend Setup
```bash
cd backend
npm install
cp .env.example .env
# Edit .env with your config
npm run dev
```

### Mobile App Setup
```bash
cd mobile
flutter pub get
cp .env.example .env
# Edit .env with your config
flutter run
```

See [docs/SETUP.md](docs/SETUP.md) for detailed instructions.

---

## 📁 Project Structure

```
DAANSETU/
├── README.md                # This file
├── CONTRIBUTING.md          # Contribution guidelines
├── LICENSE                  # MIT License
├── CODE_OF_CONDUCT.md       # Community standards
├── CHANGELOG.md             # Version history
│
├── backend/                 # Backend API (Node.js)
│   ├── config/              # Configuration
│   ├── controllers/         # Route handlers (14 files)
│   ├── middleware/          # Auth, logging, etc.
│   ├── models/              # MongoDB models (14 files)
│   ├── routes/              # API routes (v1)
│   ├── services/            # Business logic
│   ├── sockets/             # Real-time handlers
│   ├── terraform/           # Infrastructure as Code
│   └── docs/                # API documentation
│
├── mobile/                  # Flutter mobile app
│   └── lib/
│       ├── config/          # App configuration
│       ├── core/            # API client, services
│       └── features/        # Feature modules
│           ├── auth/        # Authentication
│           ├── donations/   # Donation management
│           ├── ngos/        # NGO features
│           ├── chat/        # Messaging
│           └── ...
│
└── docs/                    # Documentation
    ├── API.md               # API reference
    ├── SETUP.md             # Setup guide
    └── ARCHITECTURE.md      # System design
```

---

## 📊 API Overview

### Core Endpoints (52+ total)

| Category | Endpoints |
|----------|-----------|
| **Auth** | Register, Login, Refresh, Password Reset |
| **Donations** | CRUD, Claim, Track, Search |
| **NGOs** | List, Verify, Dashboard |
| **Verification** | Request, Steps, Bypass, Support |
| **Delivery** | Initialize, GPS Update, Confirm |
| **Chat** | Messages, Conversations |
| **Reviews** | Submit, List, Stats |
| **Admin** | Dashboard, Analytics, Fraud Alerts |

Full API docs at `http://localhost:5000/api-docs` (Swagger)

---

## 🔐 Security

- **JWT Authentication** with refresh tokens
- **Role-based access** (Donor, NGO, Admin)
- **Government API verification** for NGOs
- **Rate limiting** on sensitive endpoints
- **Input validation** on all routes
- **Complete audit logging**

---

## 🤝 Contributing

We love contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Steps
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [NGO Darpan](https://ngodarpan.gov.in) - Government NGO database
- All contributors and supporters
- NGOs working on the ground

---

## 📞 Support

- 📧 Email: support@daansetu.org
- 💬 Discord: [Join Community](https://discord.gg/daansetu)
- 🐛 Issues: [GitHub Issues](https://github.com/phcoder05/daansetu/issues)

---

<p align="center">
  Made with ❤️ for a better world<br/>
  <strong>Not just food. Everything you can give.</strong>
</p>
