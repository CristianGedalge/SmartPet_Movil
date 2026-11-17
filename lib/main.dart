import 'package:flutter/material.dart';

import 'app.dart';
import 'config/api_config.dart';
import 'features/auth/services/session.dart';
import 'shared/services/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final config = ApiConfig.fromEnvironment();
    final session = Session(ApiClient(config.apiUrl), SecureTokenStore());
    runApp(SmartPetApp(config: config, session: session));
  } on FormatException catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error.message),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
