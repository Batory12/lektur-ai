# Push Notification System Architecture

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                              │
│                                                                   │
│  ┌──────────────┐         ┌────────────────┐                    │
│  │   main.dart  │────────>│ NotificationService                 │
│  │              │         │  - initialize()                      │
│  └──────────────┘         │  - scheduleNotifications()           │
│        │                  │  - cancelAllNotifications()          │
│        │                  │  - sendTestNotification()            │
│        │                  └────────────────┘                     │
│        v                          │    │                         │
│  ┌──────────────┐                 │    │                        │
│  │  AuthWrapper │                 │    │                        │
│  └──────────────┘                 │    │                        │
│        │                          │    │                         │
│        v                          v    v                         │
│  ┌──────────────┐         ┌────────────────┐                    │
│  │ LoginScreen  │────────>│  AuthService    │                   │
│  │              │         │  - signIn()     │                   │
│  └──────────────┘         │  - reschedule() │                   │
│                           └────────────────┘                     │
│        │                                                         │
│        v                                                         │
│  ┌──────────────┐         ┌────────────────┐                    │
│  │ProfileScreen │────────>│ ProfileService  │                   │
│  │ - Dropdown   │         │ - updateFrequency()                 │
│  │ - Description│         └────────────────┘                    │
│  └──────────────┘                 │                              │
│                                   │                              │
└───────────────────────────────────┼──────────────────────────────┘
                                    │
                                    v
              ┌──────────────────────────────────────┐
              │      Firebase Cloud Services         │
              │                                      │
              │  ┌─────────────────────────────┐    │
              │  │     Cloud Firestore         │    │
              │  │  - users/{uid}/             │    │
              │  │    - notificationFrequency  │    │
              │  │    - fcmToken               │    │
              │  └─────────────────────────────┘    │
              │                                      │
              │  ┌─────────────────────────────┐    │
              │  │  Firebase Cloud Messaging   │    │
              │  │  - Token Management         │    │
              │  │  - Push Notifications       │    │
              │  └─────────────────────────────┘    │
              └──────────────────────────────────────┘
                                    │
                                    v
              ┌──────────────────────────────────────┐
              │         Android Device               │
              │                                      │
              │  ┌─────────────────────────────┐    │
              │  │ flutter_local_notifications │    │
              │  │  - Scheduled Notifications  │    │
              │  │  - ID 1: Daily/Weekly       │    │
              │  │  - ID 1-30: Every 3 days    │    │
              │  └─────────────────────────────┘    │
              │                                      │
              │  ┌─────────────────────────────┐    │
              │  │    Notification Manager     │    │
              │  │  - Display at 10:00 AM      │    │
              │  │  - Persist after reboot     │    │
              │  └─────────────────────────────┘    │
              └──────────────────────────────────────┘
```

## Data Flow

### 1. App Initialization
```
User Opens App
    │
    ├──> main.dart initializes NotificationService
    │       │
    │       ├──> Request permissions (Android 13+)
    │       ├──> Setup FCM
    │       ├──> Register FCM token
    │       └──> Save token to Firestore
    │
    └──> AuthWrapper checks login status
```

### 2. User Login
```
User Logs In
    │
    ├──> AuthService.signInWithEmailAndPassword()
    │       │
    │       ├──> Update last login time
    │       └──> Reschedule notifications
    │               │
    │               ├──> Load user preference from Firestore
    │               └──> Schedule based on frequency
    │
    └──> Navigate to HomeScreen
```

### 3. Changing Notification Frequency
```
User Opens Profile
    │
    ├──> Load current frequency
    │
    └──> User selects new frequency from dropdown
            │
            ├──> ProfileService.updateNotificationFrequency()
            │       │
            │       ├──> Save to Firestore
            │       └──> NotificationService.scheduleNotifications()
            │               │
            │               ├──> Cancel all existing notifications
            │               └──> Schedule new notifications:
            │                       │
            │                       ├─ Codziennie: Daily at 10:00 AM
            │                       ├─ Co 3 dni: 30 notifications, 3 days apart
            │                       ├─ Raz w tygodniu: Weekly Monday 10:00 AM
            │                       └─ Nigdy: No notifications
            │
            └──> Show success message
```

## Notification Scheduling Logic

### Daily (Codziennie)
```dart
Schedule:
- Next 10:00 AM
- Repeat: DateTimeComponents.time (daily)
- Count: 1 notification (repeats automatically)
```

### Every 3 Days (Co 3 dni)
```dart
Schedule:
- Day 0: Next 10:00 AM
- Day 3: 10:00 AM
- Day 6: 10:00 AM
- ...
- Day 87: 10:00 AM (90 days coverage)
- Repeat: None
- Count: 30 individual notifications
```

### Weekly (Raz w tygodniu)
```dart
Schedule:
- Next Monday 10:00 AM
- Repeat: DateTimeComponents.dayOfWeekAndTime
- Count: 1 notification (repeats automatically)
```

## Permission Flow

```
App Starts
    │
    ├──> Check if Android 13+
    │       │
    │       ├─ Yes ──> Request POST_NOTIFICATIONS permission
    │       │           │
    │       │           ├─ Granted ──> Continue
    │       │           └─ Denied ───> Notifications disabled
    │       │
    │       └─ No ───> Notifications work by default
    │
    └──> Request FCM permissions
            │
            ├─ Alert: Yes
            ├─ Badge: Yes
            └─ Sound: Yes
```

## File Structure

```
lektur-ai/
├── lekturai_front/
│   ├── lib/
│   │   ├── main.dart                    [Modified] Init notifications
│   │   ├── profile_screen.dart          [Modified] Add description
│   │   └── services/
│   │       ├── auth_service.dart        [Modified] Reschedule on login
│   │       ├── profile_service.dart     [Modified] Schedule on change
│   │       └── notification_service.dart [NEW] Core notification logic
│   │
│   ├── android/
│   │   └── app/src/main/
│   │       └── AndroidManifest.xml      [Modified] Permissions & receivers
│   │
│   ├── pubspec.yaml                     [Modified] Add dependencies
│   └── NOTIFICATIONS.md                 [NEW] Implementation guide
│
└── IMPLEMENTATION_SUMMARY.md            [NEW] This document
```

## Key Design Decisions

1. **Local Notifications**: Used `flutter_local_notifications` instead of pure FCM for better reliability and offline scheduling

2. **Every 3 Days Strategy**: Schedule 30 individual notifications (90 days ahead) instead of trying to use a custom repeat interval

3. **Singleton Pattern**: NotificationService uses singleton to ensure only one instance manages notifications

4. **Token Management**: FCM tokens are saved to Firestore with automatic refresh handling

5. **Timezone**: Fixed to 'Europe/Warsaw' for consistent scheduling

6. **Notification Time**: Fixed to 10:00 AM for simplicity (can be made configurable later)

7. **ID Strategy**: 
   - IDs 1-30: Reserved for "every 3 days" notifications
   - ID 1: Used for daily and weekly (with repeat)
   - IDs 100+: Used for immediate/test notifications

## Security Measures

- ✅ Authentication required before saving FCM tokens
- ✅ Firestore security rules control data access
- ✅ No sensitive data in notification content
- ✅ Proper permission handling
- ✅ Error handling prevents crashes
- ✅ Token refresh properly managed
