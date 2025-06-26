# DiSCon-X Flutter Mobile App

## Overview
DiSCon-X (DICT Secure Connect) is a mobile application developed for Android devices to detect and prevent evil twin attacks on public Wi-Fi networks. This is the companion mobile app to the web-based admin monitoring system.

## Features
- **Network Scanning**: Detect nearby Wi-Fi networks and verify against DICT's whitelist
- **Security Alerts**: Real-time notifications for suspicious networks
- **Network Map**: Visual representation of verified and suspicious networks
- **Educational Content**: Learn about Wi-Fi security best practices
- **Settings Management**: Customize app behavior and security preferences

## Architecture
The app follows a clean, modular architecture:
- **Provider Pattern** for state management
- **Repository Pattern** for data management
- **Firebase-ready** structure for backend integration
- **Component-based UI** with reusable widgets

## Project Structure
```
lib/
├── main.dart                 # App entry point
├── app.dart                 # Main app widget
├── core/                    # Core utilities and theme
│   ├── theme/              # App theming
│   └── constants/          # App constants
├── data/                    # Data layer
│   ├── models/             # Data models
│   ├── repositories/       # Data repositories
│   └── services/           # External services
├── presentation/            # UI layer
│   ├── screens/            # App screens
│   └── widgets/            # Reusable widgets
└── providers/              # State management
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio or VS Code with Flutter plugins
- Android device or emulator (API level 21+)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd discon_x
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Create required directories**
   ```bash
   mkdir -p assets/images assets/icons
   ```

4. **Add placeholder images**
   Place the following images in `assets/images/`:
   - `map_placeholder.png` (for map background)
   - `image1.png` (for education content)
   - `image2.png` (for education content)

5. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Integration

To integrate Firebase services:

1. **Create a Firebase project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or select existing one

2. **Add Android app to Firebase**
   - Register your app with package name: `com.dict.disconx`
   - Download `google-services.json`
   - Place it in `android/app/`

3. **Update Android configuration**
   
   In `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.3.15'
       }
   }
   ```
   
   In `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

4. **Initialize Firebase in main.dart**
   Uncomment the Firebase initialization:
   ```dart
   await Firebase.initializeApp();
   ```

## Whitelist Integration

The app is designed to fetch and utilize a whitelist from your web backend. To implement:

1. **Create a WhitelistService** in `lib/data/services/`:
   ```dart
   class WhitelistService {
     Future<List<String>> fetchWhitelist() async {
       // Implement API call to your backend
     }
   }
   ```

2. **Update NetworkProvider** to use the whitelist:
   ```dart
   void verifyNetwork(NetworkModel network) {
     if (whitelist.contains(network.macAddress)) {
       network.status = NetworkStatus.verified;
     }
   }
   ```

## Building for Production

### Android Build
```bash
# Create release build
flutter build apk --release

# Create app bundle for Play Store
flutter build appbundle --release
```

The APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

## Key Components

### Network Scanning
- Real-time network detection
- Signal strength monitoring
- Security type identification

### Security Features
- Auto-block suspicious networks
- Evil twin detection algorithm
- VPN usage suggestions

### Data Management
- Local storage with SharedPreferences
- Network history management
- User preferences persistence

## Future Enhancements
- [ ] Implement actual network scanning using platform channels
- [ ] Add Google Maps integration for real location tracking
- [ ] Implement push notifications
- [ ] Add network speed testing
- [ ] Implement QR code scanning for network authentication
- [ ] Add multi-language support (Filipino)

## Troubleshooting

### Common Issues

1. **Build errors**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Permission issues**
   Ensure all required permissions are granted in app settings

3. **Firebase connection issues**
   Verify `google-services.json` is properly configured

## Contributing
Please follow the existing code style and architecture patterns when contributing to this project.

## License
© 2025 DICT-CALABARZON. All rights reserved.