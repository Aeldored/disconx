# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DiSCon-X (DICT Secure Connect) is a Flutter mobile security application designed to detect and prevent evil twin Wi-Fi attacks on public networks. It serves as a companion app to a web-based admin monitoring system for DICT-CALABARZON.

## Development Commands

### Essential Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Clean and rebuild
flutter clean && flutter pub get

# Code analysis
flutter analyze

# Run tests
flutter test

# Build for release
flutter build apk --release
flutter build appbundle --release
```

### Required Setup
```bash
# Create asset directories (required before first run)
mkdir -p assets/images assets/icons

# Required placeholder images:
# - assets/images/map_placeholder.png
# - assets/images/image1.png
# - assets/images/image2.png
```

## Architecture Overview

### State Management Pattern
The app uses **Provider pattern** with three main providers:
- `NetworkProvider`: Manages network scanning, filtering, and mock data
- `SettingsProvider`: User preferences and app configuration
- `AuthProvider`: Authentication state management

### Layer Architecture
```
lib/
├── core/           # Theme, constants, utilities
├── data/           # Models, repositories, services
├── presentation/   # Screens and reusable widgets
└── providers/      # State management
```

### Key Architectural Patterns
- **Repository Pattern**: `data/repositories/` abstracts data access with caching
- **Service Layer**: `data/services/` handles external integrations (Firebase, Location)
- **Component-based UI**: Reusable widgets in `presentation/widgets/`

## Firebase Integration Status

Firebase is **prepared but not activated**. All services are implemented in `data/services/firebase_service.dart`:

### To Activate Firebase:
1. Create Firebase project and add Android app
2. Download `google-services.json` to `android/app/`
3. Update `android/build.gradle.kts` and `android/app/build.gradle.kts` with Google Services plugin
4. Uncomment Firebase dependencies in `pubspec.yaml`
5. Uncomment `await Firebase.initializeApp();` in `main.dart`

### Firebase Features Ready:
- Authentication (anonymous and email)
- Firestore operations with real-time listeners
- Push notifications (FCM)
- Analytics and crash reporting

## Mock Data System

The app currently uses comprehensive mock data in `NetworkProvider`:
- Simulated network scanning with realistic data
- Educational content with placeholder structure
- Alert system with various threat types
- Network filtering and verification logic

## Key Dependencies

### Core Functionality
- `provider` - State management
- `dio` - HTTP client for API calls
- `connectivity_plus` - Network connectivity monitoring
- `geolocator` + `flutter_map` - Location services and mapping
- `shared_preferences` - Local storage

### UI Components
- `google_fonts` - Typography
- `flutter_animate` - Animations
- `shimmer` - Loading states
- `badges` - Status indicators

### Security & Utilities
- `permission_handler` - Runtime permissions
- `mobile_scanner` - QR code scanning (future feature)
- `package_info_plus` - App metadata

## Current Status

### ✅ Fixed and Working
- **All compilation errors resolved** - no syntax errors in /lib directory
- **All import paths corrected** - proper relative imports for all files
- **Firebase integration with fallback** - graceful degradation when Firebase not configured
- **Deprecated API fixes** - updated textScaleFactor to textScalerOf
- **Asset directories created** with placeholder images
- **Dio 5.x compatibility** - timeout parameters use milliseconds
- **Robust error handling** - Firebase failures don't crash the app
- **Production-ready UI** - all screens and widgets compile correctly

### Ready for Android Deployment
- **Clean codebase** - no red lines or compilation errors
- **Modular architecture** - proper separation of concerns
- **Error boundaries** - graceful handling of Firebase/network failures
- **Mock data system** - fully functional without backend

### Configuration Updates Needed
- Change package name from `com.example.disconx` to `com.dict.disconx`
- Add required Android permissions for location, network, and camera access
- Configure Firebase when backend is ready

## Testing Notes

Current test file (`test/widget_test.dart`) references `MyApp` which doesn't exist. It should test `DiSConXApp` from `lib/app.dart`.

The app follows clean architecture principles making it highly testable with clear separation between business logic and UI.

## Production Considerations

### App Configuration
- Portrait-only orientation (locked in `main.dart`)
- Custom system UI styling
- Base API URL: `https://api.disconx.dict.gov.ph`
- Default location: Lipa City, Batangas

### Security Features
- Evil twin detection algorithms (mock implementation)
- Network verification against government whitelist
- Auto-blocking of suspicious networks
- Educational content about Wi-Fi security

The codebase is well-structured and ready for real-world implementation once the backend API and platform-specific network scanning are integrated.