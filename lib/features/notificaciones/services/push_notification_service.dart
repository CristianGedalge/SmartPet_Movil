import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../config/firebase_config.dart';
import '../../../shared/services/api_client.dart';
import '../../auth/services/session.dart';

class PushNotificationService implements SessionNotifications {
  PushNotificationService._({this._messaging, this._localNotifications});

  static const _channelId = 'smartpet_session';
  static const _channelName = 'Sesión de SmartPet';
  static const _channelDescription =
      'Avisos de inicio y cierre de sesión de tu cuenta.';

  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin? _localNotifications;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _fcmToken;
  int _notificationId = 1000;

  static Future<PushNotificationService> create(
    FirebasePublicConfig config,
  ) async {
    if (!config.enabled || kIsWeb) return PushNotificationService._();
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return PushNotificationService._();
    }
    try {
      await Firebase.initializeApp(options: config.options);
      final local = FlutterLocalNotificationsPlugin();
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await local.initialize(settings: initializationSettings);
      await local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDescription,
              importance: Importance.high,
            ),
          );
      final service = PushNotificationService._(
        messaging: FirebaseMessaging.instance,
        localNotifications: local,
      );
      service._foregroundSubscription = FirebaseMessaging.onMessage.listen(
        service._showForegroundNotification,
      );
      return service;
    } catch (_) {
      return PushNotificationService._();
    }
  }

  @override
  Future<void> afterLogin(ApiClient api) async {
    final messaging = _messaging;
    if (messaging == null) return;
    final permission = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (permission.authorizationStatus != AuthorizationStatus.authorized &&
        permission.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await _register(messaging);
    _fcmToken = token;
    await api.request(
      'POST',
      '/notificaciones/inicio-sesion',
      body: {'token': token},
    );
  }

  @override
  Future<void> beforeLogout(ApiClient api) async {
    var token = _fcmToken;
    final messaging = _messaging;
    if (token == null && messaging != null) {
      final permission = await messaging.getNotificationSettings();
      if (permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional) {
        token = await _register(messaging);
      }
    }
    if (token == null) return;
    try {
      await api.request(
        'POST',
        '/notificaciones/cierre-sesion',
        body: {'token': token},
      );
    } finally {
      _fcmToken = null;
    }
  }

  Future<String> _register(FirebaseMessaging messaging) async {
    final registration = messaging.onRegistered.first.timeout(
      const Duration(seconds: 15),
    );
    await messaging.register();
    return registration;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final localNotifications = _localNotifications;
    if (notification == null || localNotifications == null) return;
    await localNotifications.show(
      id: _notificationId++,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_foregroundSubscription?.cancel());
  }
}
