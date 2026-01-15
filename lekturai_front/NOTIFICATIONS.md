# Android Push Notifications - Implementation Guide

## Overview

This document describes the implementation of push notifications for Android in the Lektur.ai app. The notification system reminds users to study for their matura exam based on their configured frequency preference.

## Features

- **Firebase Cloud Messaging (FCM)** integration for push notifications
- **Local scheduled notifications** for reminder functionality
- **Four frequency options**:
  - `Codziennie` (Daily) - Notifications at 10:00 AM every day
  - `Co 3 dni` (Every 3 days) - Notifications at 10:00 AM every third day
  - `Raz w tygodniu` (Weekly) - Notifications at 10:00 AM every Monday
  - `Nigdy` (Never) - No notifications

## Implementation Details

### 1. Dependencies Added

```yaml
firebase_messaging: ^15.0.4      # Firebase Cloud Messaging
flutter_local_notifications: ^18.0.1  # Local notifications
timezone: ^0.9.4                 # Timezone support for scheduling
```

### 2. Android Build Configuration (build.gradle.kts)

Core library desugaring must be enabled for `flutter_local_notifications`:

```kotlin
android {
    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
```

This enables Java 8+ features on older Android versions.

### 3. Android Permissions (AndroidManifest.xml)

The following permissions were added:
- `INTERNET` - For network communication
- `POST_NOTIFICATIONS` - For Android 13+ notification permission
- `RECEIVE_BOOT_COMPLETED` - To reschedule notifications after device reboot
- `SCHEDULE_EXACT_ALARM` - For precise notification timing
- `USE_EXACT_ALARM` - Alternative alarm permission

### 4. NotificationService

Location: `lib/services/notification_service.dart`

#### Key Methods:

- **`initialize()`** - Initializes notification service, requests permissions, and sets up FCM
- **`scheduleNotifications(String frequency)`** - Schedules notifications based on user preference
- **`cancelAllNotifications()`** - Cancels all scheduled notifications
- **`sendTestNotification()`** - Sends a test notification immediately

#### How Scheduling Works:

1. **Daily (Codziennie)**:
   - Uses `DateTimeComponents.time` to repeat at the same time every day
   - Scheduled for 10:00 AM

2. **Every 3 Days (Co 3 dni)**:
   - Schedules 30 individual notifications (covering 90 days)
   - Each notification is 3 days apart
   - When frequency changes, old notifications are cancelled and new ones scheduled

3. **Weekly (Raz w tygodniu)**:
   - Uses `DateTimeComponents.dayOfWeekAndTime` to repeat weekly
   - Scheduled for Monday at 10:00 AM

4. **Never (Nigdy)**:
   - Cancels all scheduled notifications

### 5. Integration Points

#### Profile Service
- When user changes notification frequency in profile, `NotificationService().scheduleNotifications()` is called
- Location: `lib/services/profile_service.dart`

#### Auth Service
- When user logs in, notifications are rescheduled based on their stored preference
- Ensures notifications persist across app sessions
- Location: `lib/services/auth_service.dart`

#### Main.dart
- Notification service is initialized when app starts
- Location: `lib/main.dart`

### 6. Notification Content

**Title**: "Czas na naukę! 📚" (Time to study!)

**Body**: "Przypomnij sobie o swoim celu - egzamin maturalny zbliża się!" (Remember your goal - the matura exam is approaching!)

## User Flow

1. User opens the app and logs in
2. Notification service initializes and requests permissions
3. User navigates to Profile screen
4. User selects notification frequency from dropdown
5. When frequency is changed:
   - Old notifications are cancelled
   - New notifications are scheduled based on selected frequency
   - User sees success message
6. Notifications are delivered at scheduled times (10:00 AM)

## Testing

### Test Notification
To test that notifications are working, you can add a button in the profile screen:

```dart
ElevatedButton(
  onPressed: () async {
    await NotificationService().sendTestNotification();
  },
  child: Text('Test Notification'),
)
```

### Verify Scheduled Notifications
Check if notifications are scheduled:
```dart
final pendingNotifications = await _localNotifications.pendingNotificationRequests();
print('Pending notifications: ${pendingNotifications.length}');
```

## Troubleshooting

### Notifications not appearing

1. **Check permissions**: Ensure POST_NOTIFICATIONS permission is granted on Android 13+
2. **Check timezone**: Verify timezone is correctly set to 'Europe/Warsaw'
3. **Check scheduled time**: Ensure notifications aren't scheduled in the past
4. **Check FCM token**: Verify FCM token is saved to Firestore

### After device reboot

Notifications should automatically reschedule thanks to the `RECEIVE_BOOT_COMPLETED` permission and boot receiver configured in AndroidManifest.xml.

### User not receiving notifications after login

The `auth_service.dart` reschedules notifications on login, ensuring the user's preference is applied.

## Backend Integration (Optional)

Currently, notifications are scheduled locally on the device. For more advanced features like:
- Server-triggered notifications
- Dynamic notification content
- Analytics on notification delivery

You can implement a backend service using Firebase Cloud Functions to send notifications via FCM tokens stored in Firestore.

## Security Considerations

- FCM tokens are stored securely in Firestore with user authentication
- Notification content is not sensitive
- Users can disable notifications at any time through profile settings

## Future Enhancements

1. **Custom notification times**: Allow users to choose their preferred notification time
2. **Smart scheduling**: Adjust notification times based on user's study patterns
3. **Rich notifications**: Add action buttons (e.g., "Start studying", "Snooze")
4. **Notification history**: Track which notifications were delivered and opened
5. **Backend integration**: Server-side notification management for better control
