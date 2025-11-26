# Firebase Authentication Setup

This Flutter app now includes Firebase Authentication with Firestore integration. Here's what has been implemented:

## 🚀 Features Added

### Authentication Service (`lib/services/auth_service.dart`)
- Email/password registration and login
- Password reset functionality
- User document creation in Firestore
- Polish error messages
- Automatic last login tracking

### Screens
- **Login Screen** - Email/password login with validation
- **Register Screen** - User registration with form validation
- **Auth Wrapper** - Automatic authentication state management

### User Management
- User profiles stored in Firestore with:
  - UID, email, display name
  - Creation and last login timestamps
- Logout functionality in profile screen

## 📦 Dependencies Added
- `firebase_core: ^3.4.0`
- `firebase_auth: ^5.1.2` 
- `cloud_firestore: ^5.0.1`

## ⚙️ Setup Instructions

### 1. Firebase Project Setup
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project or use existing one
3. Enable Authentication with Email/Password provider
4. Enable Firestore Database

### 2. Configure Firebase for Flutter
Run the FlutterFire CLI to generate configuration:

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will update `lib/firebase_options.dart` with your actual Firebase configuration.

### 3. Android Setup (if targeting Android)
Add the `google-services.json` file to `android/app/`

### 4. iOS Setup (if targeting iOS)  
Add the `GoogleService-Info.plist` file to `ios/Runner/`

### 5. Web Setup (if targeting Web)
Update `web/index.html` with Firebase SDK scripts

## 🔧 Configuration Files Modified

- `lib/main.dart` - Added Firebase initialization and auth routes
- `lib/firebase_options.dart` - Firebase configuration (needs real values)
- `pubspec.yaml` - Firebase dependencies already added

## 🔄 Navigation Flow

1. **App Start** → `AuthWrapper` checks authentication state
2. **Not Logged In** → `LoginScreen`
3. **Logged In** → `HomeScreen`
4. **Register** → `RegisterScreen` → Auto-login → `HomeScreen`
5. **Logout** → Profile screen logout → `LoginScreen`

## 📋 Firestore Structure

Users collection:
```javascript
users/{userId} {
  uid: string,
  email: string,
  displayName: string,
  createdAt: timestamp,
  lastLoginAt: timestamp
}
```

## 🔐 Security Features

- Form validation for all input fields
- Password strength requirements (minimum 6 characters)
- Password confirmation matching
- Firebase security rules (configure in Firebase Console)
- Proper error handling with Polish messages

## 🚨 Important Notes

- Update `firebase_options.dart` with your real Firebase configuration
- Configure Firestore security rules in Firebase Console
- Test authentication flow thoroughly before production
- Consider adding email verification for production apps

## 🎯 Next Steps

1. Replace placeholder Firebase config with real values
2. Set up Firestore security rules
3. Add email verification (optional)
4. Add password strength indicator (optional)
5. Add social login providers (optional)
