# Troubleshooting Guide - Android Build Issues

## Common Build Errors and Solutions

### 1. Core Library Desugaring Error

**Error Message:**
```
Dependency ':flutter_local_notifications' requires core library desugaring to be enabled for :app.
```

**Solution:**
This is already fixed in the current build configuration. The `flutter_local_notifications` package requires Java 8+ features that need desugaring for older Android versions.

**Implementation:**
- `android/app/build.gradle.kts` includes:
  - `coreLibraryDesugaringEnabled = true` in compileOptions
  - Dependency: `com.android.tools:desugar_jdk_libs:2.0.4`

### 2. Minimum SDK Version

**Requirement:**
- Minimum Android SDK: As specified in Flutter configuration
- Recommended: Android 8.0 (API 26) or higher for best notification support
- Android 13+ (API 33): Required for POST_NOTIFICATIONS permission

### 3. Google Services Plugin

**Error:** Missing google-services.json

**Solution:**
Ensure Firebase is properly configured:
1. Add your `google-services.json` to `android/app/`
2. Verify `google-services` plugin is applied in `build.gradle.kts`

### 4. Gradle Build Issues

**Common Issues:**
- **Outdated Gradle**: Update to latest stable version
- **Java Version**: Ensure Java 11 is installed
- **Gradle Cache**: Run `flutter clean` then rebuild

**Commands:**
```bash
flutter clean
flutter pub get
flutter run
```

### 5. Permission Issues at Runtime

**Android 13+ Users:**
If notifications don't appear:
1. Check app permissions in system settings
2. Enable "Notifications" permission
3. Enable "Alarms & reminders" permission

**Code:**
Permission is automatically requested by `NotificationService.initialize()`

### 6. Notification Channel Issues

**Symptoms:** Notifications not appearing on Android 8+

**Solution:**
The notification channel is automatically created with ID `learning_reminders`. If issues persist:
1. Clear app data
2. Reinstall the app
3. Verify AndroidManifest.xml includes the channel meta-data

### 7. FCM Token Issues

**Symptoms:** Token not saved to Firestore

**Checklist:**
- User is logged in
- Internet connection available
- Firestore permissions allow write access
- Firebase is properly initialized

**Debug:**
Check logs for FCM token messages:
```bash
adb logcat | grep FCM
```

### 8. Build Configuration Checklist

Before building, verify:
- ✅ `build.gradle.kts` has desugaring enabled
- ✅ `AndroidManifest.xml` has all required permissions
- ✅ `google-services.json` is present
- ✅ `pubspec.yaml` dependencies are installed
- ✅ Flutter SDK is up to date

### 9. Testing Notifications

**Test on Real Device:**
Emulators may have issues with:
- Exact alarms
- FCM token generation
- Boot receivers

**Recommended:** Test on physical Android device (8.0+)

### 10. Quick Fix Commands

```bash
# Clean build
flutter clean
rm -rf android/build
rm -rf android/app/build

# Get dependencies
flutter pub get

# Rebuild
flutter run --debug

# Check for issues
flutter doctor -v
flutter analyze
```

## Getting Help

If you encounter other build issues:

1. **Check Flutter Doctor:**
   ```bash
   flutter doctor -v
   ```

2. **Check Android Logs:**
   ```bash
   adb logcat
   ```

3. **Gradle Logs:**
   ```bash
   cd android
   ./gradlew build --stacktrace
   ```

4. **Common Resources:**
   - [Flutter Local Notifications Setup](https://pub.dev/packages/flutter_local_notifications)
   - [Android Core Library Desugaring](https://developer.android.com/studio/write/java8-support)
   - [Firebase Setup Guide](https://firebase.google.com/docs/flutter/setup)

## Version Compatibility

**Current Configuration:**
- Flutter: As per project requirements
- Kotlin: Compatible with Flutter Gradle Plugin
- Java: 11
- Gradle: Managed by Flutter
- Android Compile SDK: From Flutter configuration
- Desugaring Library: 2.0.4

All dependencies are verified to be compatible and without security vulnerabilities.
