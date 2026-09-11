import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('Background message received: ${message.messageId}', name: 'NotificationService');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  bool _initialized = false;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;

    await _requestPermission();
    await _initLocalNotifications();
    await _setupFirebaseMessaging();
    await _getToken();

    _initialized = true;
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
      carPlay: false,
    );

    _log('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _setupFirebaseMessaging() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpen(initialMessage);
    }
  }

  Future<void> _getToken() async {
    _fcmToken = await _messaging.getToken();
    _log('FCM Token: $_fcmToken');

    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _log('FCM Token refreshed: $token');
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    _log('Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        id: message.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  void _handleNotificationOpen(RemoteMessage message) {
    _log('Notification opened: ${message.data}');

    _navigateFromPayload(message.data);
  }

  void _onNotificationTap(NotificationResponse response) {
    _log('Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      _navigateFromPayload({'route': response.payload!});
    }
  }

  void _navigateFromPayload(Map<String, dynamic> payload) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    final route = payload['route'] as String?;
    final courseId = payload['courseId'] as String?;
    final lessonId = payload['lessonId'] as String?;

    if (courseId != null) {
      navigator.pushNamed('/course-detail', arguments: courseId);
    } else if (lessonId != null) {
      navigator.pushNamed('/lesson', arguments: lessonId);
    } else if (route != null && route.isNotEmpty) {
      navigator.pushNamed(route);
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'pagepilot_channel',
      'PagePilot Notifications',
      channelDescription: 'Notifications from PagePilot app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _showLocalNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: payload,
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
    _log('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
    _log('Unsubscribed from topic: $topic');
  }

  Future<void> deleteToken() async {
    await _messaging.deleteToken();
    _fcmToken = null;
    _log('FCM token deleted');
  }

  void _log(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'NotificationService');
    }
  }
}
