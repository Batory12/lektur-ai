import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

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

  // Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));

      // Request notification permissions
      await _requestPermissions();

      // Configure local notifications
      await _configureLocalNotifications();

      // Configure Firebase messaging
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
    if (Platform.isAndroid) {
      // Request Android 13+ notification permission
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
    }

    // Request FCM permissions
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
      _showLocalNotification(
        title: message.notification!.title ?? 'Przypomnienie',
        body: message.notification!.body ?? '',
      );
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

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
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

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error saving device token: $e');
    }
  }

  // Schedule notification based on frequency
  Future<void> scheduleNotifications(String frequency) async {
    // Cancel all existing scheduled notifications
    await cancelAllNotifications();

    if (frequency == 'Nigdy') {
      print('Notifications disabled');
      return;
    }

    // Calculate next notification time based on frequency
    DateTime nextNotification = _calculateNextNotificationTime(frequency);
    
    // Schedule the notification
    await _scheduleNotification(
      id: 1,
      title: 'Czas na naukę! 📚',
      body: 'Przypomnij sobie o swoim celu - egzamin maturalny zbliża się!',
      scheduledDate: nextNotification,
      frequency: frequency,
    );

    print('Notification scheduled for: $nextNotification with frequency: $frequency');
  }

  // Calculate next notification time based on frequency
  DateTime _calculateNextNotificationTime(String frequency) {
    DateTime now = DateTime.now();
    DateTime scheduled;

    // Set notification time to 10:00 AM
    scheduled = DateTime(now.year, now.month, now.day, 10, 0);

    // If today's time has passed, start from tomorrow
    if (now.hour >= 10) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    // Adjust based on frequency
    switch (frequency) {
      case 'Codziennie':
        // Already set to next 10:00 AM
        break;
      case 'Co 3 dni':
        // If it's been scheduled, add 3 days
        // For first time, keep the next 10:00 AM
        break;
      case 'Raz w tygodniu':
        // Schedule for next Monday at 10:00 AM
        int daysUntilMonday = (DateTime.monday - scheduled.weekday + 7) % 7;
        if (daysUntilMonday == 0 && now.hour >= 10) {
          daysUntilMonday = 7; // Next week
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

    // Calculate repeat interval
    RepeatInterval? repeatInterval;
    switch (frequency) {
      case 'Codziennie':
        repeatInterval = RepeatInterval.daily;
        break;
      case 'Co 3 dni':
        // Flutter local notifications doesn't support every 3 days directly
        // We'll need to reschedule after each notification
        repeatInterval = null;
        break;
      case 'Raz w tygodniu':
        repeatInterval = RepeatInterval.weekly;
        break;
      default:
        repeatInterval = null;
    }

    // Schedule the notification
    if (repeatInterval != null) {
      // For daily and weekly
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatInterval == RepeatInterval.daily
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    } else {
      // For every 3 days - schedule single notification
      // We'll need to reschedule after it fires
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        _convertToTZDateTime(scheduledDate),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  // Convert DateTime to TZDateTime
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('Europe/Warsaw');
    return tz.TZDateTime.from(dateTime, location);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
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
}
