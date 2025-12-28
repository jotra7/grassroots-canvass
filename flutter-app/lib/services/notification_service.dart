import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message if needed
}

/// Service for managing push notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  late FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  String? _fcmToken;

  /// Get the current FCM token
  String? get fcmToken => _fcmToken;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase first
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Now we can get FirebaseMessaging instance
      _messaging = FirebaseMessaging.instance;

      // Set up background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      // Initialize local notifications
      await _initLocalNotifications();

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        await _saveTokenToSupabase(_fcmToken!);
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
    } catch (e) {
      // Firebase might not be available (e.g., on simulator)
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('user_devices').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'device_type': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, fcm_token',
      );
    } catch (e) {
      // Silently fail - notification registration shouldn't block app
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    // Show local notification
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['route'],
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle navigation based on message data
    final route = message.data['route'];
    if (route != null) {
      // Navigate to the appropriate screen
      // This would need to be connected to your navigation system
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle local notification tap
    final route = response.payload;
    if (route != null) {
      // Navigate to the appropriate screen
    }
  }

  /// Schedule a callback reminder
  Future<void> scheduleCallbackReminder({
    required String voterId,
    required String voterName,
    required String voterAddress,
    required DateTime reminderTime,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('callback_reminders').insert({
        'user_id': userId,
        'voter_unique_id': voterId,
        'reminder_at': reminderTime.toIso8601String(),
      });

      // Also schedule a local notification as backup
      await _localNotifications.zonedSchedule(
        voterId.hashCode,
        'Callback Reminder',
        'Remember to contact $voterName at $voterAddress',
        _convertToTZDateTime(reminderTime),
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'reminders_channel',
            'Reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'voter:$voterId',
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a scheduled reminder
  Future<void> cancelReminder(String voterId) async {
    await _localNotifications.cancel(voterId.hashCode);

    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('callback_reminders')
          .delete()
          .eq('voter_unique_id', voterId)
          .eq('sent', false);
    } catch (_) {}
  }

  /// Show a local notification immediately
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      NotificationDetails(
        android: const AndroidNotificationDetails(
          'general_channel',
          'General Notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Remove FCM token when user logs out
  Future<void> removeToken() async {
    if (_fcmToken == null) return;

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        await supabase
            .from('user_devices')
            .delete()
            .eq('user_id', userId)
            .eq('fcm_token', _fcmToken!);
      }
    } catch (_) {}
  }

  // Helper to convert DateTime to TZDateTime
  // This is a simplified version - for production, use timezone package
  dynamic _convertToTZDateTime(DateTime dateTime) {
    // The flutter_local_notifications package expects TZDateTime
    // For now, we use the basic DateTime which works for most cases
    return dateTime;
  }
}
