import 'package:flutter/material.dart';

import 'app.dart';
import 'config/api_config.dart';
import 'config/firebase_config.dart';
import 'features/auth/services/session.dart';
import 'features/notificaciones/services/push_notification_service.dart';
import 'shared/services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final config = ApiConfig.fromEnvironment();
    final pushNotifications = await PushNotificationService.create(
      FirebasePublicConfig.fromEnvironment(),
    );
    final session = Session(
      ApiClient(config.apiUrl),
      SecureTokenStore(),
      notifications: pushNotifications,
    );
    runApp(SmartPetApp(config: config, session: session));
  } on FormatException {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No pudimos iniciar SmartPet. Cierra la aplicación y vuelve a intentarlo.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
