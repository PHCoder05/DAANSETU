# DAANSETU Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                           DAANSETU                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐           │
│  │   Donor App  │    │   NGO App    │    │  Admin Panel │           │
│  │   (Flutter)  │    │   (Flutter)  │    │    (Web)     │           │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘           │
│         │                    │                    │                  │
│         └────────────────────┼────────────────────┘                  │
│                              │                                       │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                     API Gateway                                │  │
│  │              (Express.js + Rate Limiting)                      │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                              │                                       │
│         ┌────────────────────┼────────────────────┐                  │
│         ▼                    ▼                    ▼                  │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────────┐            │
│  │  REST API   │    │  Socket.IO   │    │  Background  │            │
│  │  Endpoints  │    │  Real-time   │    │    Jobs      │            │
│  └─────────────┘    └──────────────┘    └──────────────┘            │
│         │                    │                    │                  │
│         └────────────────────┼────────────────────┘                  │
│                              ▼                                       │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                      MongoDB                                   │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                      │
│  External APIs:                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │
│  │ NGO Darpan  │  │   80G API   │  │   MCA API   │                  │
│  └─────────────┘  └─────────────┘  └─────────────┘                  │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Database Collections

| Collection | Purpose |
|------------|---------|
| `users` | User accounts (donors, NGOs, admins) |
| `donations` | Food donation listings |
| `messages` | Chat messages |
| `notifications` | Push notification records |
| `verifications` | NGO verification requests |
| `delivery_tracking` | GPS tracking data |
| `activity_logs` | Audit trail |
| `fraud_alerts` | Suspicious activity |
| `support_requests` | Help desk tickets |

## API Versioning

All endpoints are prefixed with `/api/v1/`

## Security Layers

1. **Authentication**: JWT tokens
2. **Authorization**: Role-based access (donor, ngo, admin)
3. **Validation**: express-validator
4. **Rate Limiting**: Per-endpoint limits
5. **Audit**: All actions logged
