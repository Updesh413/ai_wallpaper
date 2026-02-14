# AI Wallpaper App

A modern Flutter application for discovering and setting AI-generated (and Pexels) wallpapers. This project follows Clean Architecture and uses Firebase for backend services.

## Features

- **Google Sign-In**: Secure and easy authentication via Google.
- **Browse Wallpapers**: Explore a vast collection of wallpapers curated for high-quality displays.
- **Set Wallpaper**: Directly set images as home screen, lock screen, or both with a single tap.
- **Biometric Lock**: Protect your application with fingerprint or face ID.
- **Push Notifications**: Stay updated with new wallpaper collections and app updates via Firebase Cloud Messaging.
- **Ads Integration**: Monetized with Google Mobile Ads (Banner and Interstitial ads).
- **Responsive UI**: Built with a modern aesthetic, featuring smooth animations (Lottie) and shimmer effects.
- **In-App Updates**: Prompt users to update to the latest version seamlessly.

## Architecture

The project follows **Clean Architecture** principles to ensure scalability and maintainability:
- **Data**: Implementation of repositories and data sources (API calling with Dio/Http, Firebase interactions).
- **Domain**: Pure business logic containing Entities and Use cases.
- **Presentation**: UI layer using **Provider** for state management and **GetIt** for dependency injection.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Provider
- **Dependency Injection**: GetIt
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **External API**: Pexels API (via `flutter_dotenv`)
- **Local Database**: Shared Preferences
- **Key Libraries**: 
  - `firebase_core`, `firebase_auth`, `cloud_firestore`
  - `google_mobile_ads`
  - `google_sign_in`
  - `lottie` (Animations)
  - `shimmer` (Loading states)
  - `connectivity_plus` (Network status)
  - `local_auth` (Biometrics)
  - `flutter_wallpaper_manager`

## Prerequisites

- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase Account
- Pexels API Key

## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/your-username/ai_wallpaper.git
cd ai_wallpaper
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration
1. Create a new project in the [Firebase Console](https://console.firebase.google.com/).
2. **Android Setup**:
   - Register the app with package name: `com.Updesh.AIWallpaper`.
   - Download `google-services.json` and place it in `android/app/`.
3. **iOS Setup**:
   - Register the app with bundle ID: `com.Updesh.AIWallpaper`.
   - Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
4. Enable **Google Sign-In** in the Firebase Authentication settings.
5. Setup **Firestore Database** and **Firebase Storage**.
6. **AdMob Setup**:
   - Update your AdMob App ID in `android/app/src/main/AndroidManifest.xml`.
   - Update your AdMob App ID in `ios/Runner/Info.plist`.

### 4. Environment Variables
Create a `.env` file in the root directory and add your Pexels API key:
```env
PEXELS_API=your_pexels_api_key_here
```

### 5. Running the App
```bash
flutter run
```

## Project Structure
```
lib/
├── core/                  # Core utilities, error handling, and base use cases
├── features/              # Feature-based modules (Clean Architecture)
│   ├── auth/              # Authentication feature (Data, Domain, Presentation)
│   └── wallpaper/         # Wallpaper feature (Data, Domain, Presentation)
├── models/                # Global data models
├── screens/               # General app screens (Splash, Settings)
├── services/              # External services (Biometrics, Notifications)
├── theme/                 # App theme configuration
└── widgets/               # Reusable UI components
```

## Contributing
Contributions are welcome! Please feel free to submit a Pull Request.
