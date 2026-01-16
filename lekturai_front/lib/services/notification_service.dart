import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;

// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;
  bool _tokenRefreshListenerSet = false;
  int _notificationIdCounter = 100; // Start from 100 to avoid conflicts with scheduled ones

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Skip timezone and local notifications on web
      if (!kIsWeb) {
        // Initialize timezone (not available on web)
        tz.initializeTimeZones();
        tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));
      }

      // Request notification permissions
      await _requestPermissions();

      // Configure local notifications (only on mobile)
      if (!kIsWeb) {
        await _configureLocalNotifications();
      }

      // Configure Firebase messaging (works on both web and mobile)
      await _configureFirebaseMessaging();

      // Get and save FCM token
      await _saveDeviceToken();

      _initialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    // Skip Android-specific permissions on web
    if (!kIsWeb) {
      // Request Android 13+ notification permission
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }

    // Request FCM permissions (works on both web and mobile)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  // Configure local notifications
  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'learning_reminders',
      'Przypomnienia o nauce',
      description: 'Powiadomienia przypominające o nauce do matury',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Configure Firebase messaging
  Future<void> _configureFirebaseMessaging() async {
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');
    
    if (message.notification != null) {
      // Only show local notification on mobile (web shows browser notifications automatically)
      if (!kIsWeb) {
        _showLocalNotification(
          title: message.notification!.title ?? 'Przypomnienie',
          body: message.notification!.body ?? '',
        );
      }
    }
  }

  // Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.messageId}');
    // Navigate to appropriate screen based on notification data
  }

  // Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Navigate to appropriate screen
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Skip on web - browser handles notifications
    if (kIsWeb) {
      print('Web notification: $title - $body');
      return;
    }

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'learning_reminders',
      'Przypomnienia o nauce',
      channelDescription: 'Powiadomienia przypominające o nauce do matury',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Use counter for ID to avoid conflicts
    _notificationIdCounter++;
    await _localNotifications.show(
      _notificationIdCounter,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Save device token to Firestore
  Future<void> _saveDeviceToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _firebaseMessaging.getToken();
      if (token == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });

      print('FCM token saved: $token');

      // Set up token refresh listener only once
      if (!_tokenRefreshListenerSet) {
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          _updateDeviceToken(newToken);
        });
        _tokenRefreshListenerSet = true;
      }
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  // Update device token when it refreshes
  Future<void> _updateDeviceToken(String newToken) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': newToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      print('FCM token updated: $newToken');
    } catch (e) {
      print('Error updating device token: $e');
    }
  }

  // Schedule notification based on frequency
  Future<void> scheduleNotifications(String frequency, {int hour = 10, int minute = 0}) async {
    // Local scheduled notifications not supported on web
    if (kIsWeb) {
      print('Scheduled notifications are not supported on web. Use Firebase Cloud Messaging from server.');
      return;
    }

    // Cancel all existing scheduled notifications
    await cancelAllNotifications();

    if (frequency == 'Nigdy') {
      print('Notifications disabled');
      return;
    }

    // For "every 3 days", we need to schedule multiple notifications
    if (frequency == 'Co 3 dni') {
      await _scheduleEveryThreeDaysNotifications(hour: hour, minute: minute);
    } else {
      // For daily and weekly, schedule with repeat
      DateTime nextNotification = _calculateNextNotificationTime(frequency, hour: hour, minute: minute);
      await _scheduleNotification(
        id: 1,
        title: 'Czas na naukę! 📚',
        body: 'Przypomnij sobie o swoim celu - egzamin maturalny zbliża się!',
        scheduledDate: nextNotification,
        frequency: frequency,
      );
    }

    print('Notifications scheduled for frequency: $frequency at $hour:${minute.toString().padLeft(2, '0')}');
  }

  // Schedule multiple notifications for every 3 days (up to 3 months ahead)
  Future<void> _scheduleEveryThreeDaysNotifications({int hour = 10, int minute = 0}) async {
    DateTime scheduled = _getNextScheduledTime(DateTime.now(), hour: hour, minute: minute);

    // Schedule notifications every 3 days for the next 90 days (30 notifications)
    for (int i = 0; i < 30; i++) {
      DateTime notificationTime = scheduled.add(Duration(days: i * 3));
      
      await _localNotifications.zonedSchedule(
        i + 1, // ID from 1 to 30
        'Czas na naukę! 📚',
        'Przypomnij sobie o swoim celu - egzamin maturalny zbliża się!',
        _convertToTZDateTime(notificationTime),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'learning_reminders',
            'Przypomnienia o nauce',
            channelDescription: 'Powiadomienia przypominające o nauce do matury',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    
    print('Scheduled 30 notifications every 3 days');
  }

  // Helper method to get next scheduled time at custom time
  DateTime _getNextScheduledTime(DateTime now, {int hour = 10, int minute = 0}) {
    DateTime scheduled = DateTime(now.year, now.month, now.day, hour, minute);
    
    // If today's time has passed, start from tomorrow
    if (now.hour > hour || (now.hour == hour && now.minute >= minute)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    
    return scheduled;
  }

  // Calculate next notification time based on frequency
  DateTime _calculateNextNotificationTime(String frequency, {int hour = 10, int minute = 0}) {
    DateTime now = DateTime.now();
    DateTime scheduled = _getNextScheduledTime(now, hour: hour, minute: minute);

    // Adjust based on frequency
    switch (frequency) {
      case 'Codziennie':
        // Already set to next scheduled time
        break;
      case 'Raz w tygodniu':
        // Schedule for next Monday at specified time
        int daysUntilMonday = (DateTime.monday - scheduled.weekday + 7) % 7;
        if (daysUntilMonday == 0 && scheduled.isBefore(now)) {
          // If it's Monday but time has passed, schedule for next Monday
          daysUntilMonday = 7;
        }
        scheduled = scheduled.add(Duration(days: daysUntilMonday));
        break;
    }

    return scheduled;
  }

  // Schedule a notification
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String frequency,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'learning_reminders',
      'Przypomnienia o nauce',
      channelDescription: 'Powiadomienia przypominające o nauce do matury',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Calculate match components for repeating notifications
    DateTimeComponents? matchComponents;
    switch (frequency) {
      case 'Codziennie':
        matchComponents = DateTimeComponents.time;
        break;
      case 'Raz w tygodniu':
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      default:
        matchComponents = null;
    }

    // Schedule the notification
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      _convertToTZDateTime(scheduledDate),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  // Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('Europe/Warsaw');
    return tz.TZDateTime.from(dateTime, location);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (kIsWeb) {
      print('Cancel notifications: not supported on web');
      return;
    }
    await _localNotifications.cancelAll();
    print('All notifications cancelled');
  }

  // Send immediate test notification
  Future<void> sendTestNotification() async {
    await _showLocalNotification(
      title: 'Test przypomnienia 📚',
      body: 'To jest testowe powiadomienie. Twoje przypomnienia działają!',
    );
  }

  // Get pending notification count (for debugging)
  Future<int> getPendingNotificationCount() async {
    if (kIsWeb) return 0;
    final pending = await _localNotifications.pendingNotificationRequests();
    return pending.length;
  }

  // Get list of pending notifications (for debugging)
  Future<List<String>> getPendingNotificationsList() async {
    if (kIsWeb) return ['Web platform: local scheduled notifications not supported'];
    final pending = await _localNotifications.pendingNotificationRequests();
    return pending.map((notif) => 
      'ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}'
    ).toList();
  }
}
