# DAANSETU Mobile App

A Flutter mobile application for the DAANSETU donation management platform.

## 🚀 Quick Start

### Prerequisites

1. **Install Flutter SDK**
   - Download from: https://flutter.dev/docs/get-started/install/windows
   - Or use Chocolatey: `choco install flutter`
   - Add to PATH: `C:\flutter\bin`

2. **Verify Installation**
   ```bash
   flutter doctor
   ```

3. **Install Android Studio** (for Android development)
   - Download: https://developer.android.com/studio
   - Install Android SDK and emulator

### Running the App

```bash
# Navigate to mobile directory
cd d:\EDI\DAANSETU\mobile

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Run on specific device
flutter devices              # List devices
flutter run -d <device_id>   # Run on specific device
```

### Available Commands

| Command | Description |
|---------|-------------|
| `flutter run` | Run in debug mode |
| `flutter run --release` | Run in release mode |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS app |
| `flutter test` | Run unit tests |
| `flutter analyze` | Analyze code |

## 📱 Features

### For Donors
- Create & manage donations
- View donation status
- Approve/reject NGO requests
- Review NGOs after delivery

### For NGOs
- Browse available donations
- Claim donations
- Update delivery status
- Manage requests

### For Admin
- User management
- NGO verification
- Platform analytics

## 🏗️ Project Structure

```
lib/
├── main.dart               # Entry point
├── app.dart                # App configuration
├── config/
│   ├── constants.dart      # App constants
│   ├── theme.dart          # Theme configuration
│   └── routes.dart         # Navigation routes
├── core/
│   └── api/
│       ├── api_client.dart      # HTTP client
│       └── auth_interceptor.dart # JWT handling
├── features/
│   ├── auth/               # Login, Register, Splash
│   ├── donations/          # Donation CRUD
│   ├── ngos/               # NGO listing
│   ├── notifications/      # Alerts
│   ├── profile/            # User profile
│   └── dashboard/          # Main shell
└── shared/
    ├── models/             # Data models
    ├── providers/          # State management
    └── widgets/            # Reusable widgets
```

## ⚙️ Configuration

### API URL

Update the API base URL in `lib/config/constants.dart`:

```dart
static const String apiBaseUrl = 'http://localhost:5000/api';
// For production:
// static const String apiBaseUrl = 'https://your-domain.com/api';
```

## 🎨 Theme

The app uses a premium dark theme with:
- Cyan & Purple accent colors
- Glassmorphic cards
- Smooth animations
- Google Fonts (Inter)

## 📦 Key Dependencies

- **flutter_riverpod** - State management
- **dio** - HTTP client
- **go_router** - Navigation
- **flutter_animate** - Animations
- **cached_network_image** - Image caching
- **flutter_secure_storage** - Secure token storage

## 🔧 Development

### Generate code (models, retrofit)
```bash
flutter pub run build_runner build
```

### Watch mode
```bash
flutter pub run build_runner watch
```

## 📄 License

MIT License
