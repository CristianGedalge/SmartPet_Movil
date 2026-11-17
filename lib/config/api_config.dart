import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig({
    required String apiUrl,
    required this.mapStyleUrl,
    bool release = kReleaseMode,
  }) : apiUrl = apiUrl.replaceFirst(RegExp(r'/+$'), '') {
    final api = Uri.tryParse(this.apiUrl);
    final style = Uri.tryParse(mapStyleUrl);
    if (api == null ||
        !api.hasAuthority ||
        !['http', 'https'].contains(api.scheme) ||
        api.userInfo.isNotEmpty ||
        api.hasQuery ||
        api.hasFragment ||
        !api.path.endsWith('/api/v1')) {
      throw const FormatException(
        'API_URL debe ser una URL válida terminada en /api/v1.',
      );
    }
    if (release && api.scheme != 'https') {
      throw const FormatException(
        'La versión de producción requiere API_URL con HTTPS.',
      );
    }
    if (style == null || style.scheme != 'https' || !style.hasAuthority) {
      throw const FormatException(
        'MAP_STYLE_URL debe ser una URL HTTPS válida.',
      );
    }
  }

  factory ApiConfig.fromEnvironment() {
    const api = String.fromEnvironment('API_URL');
    return ApiConfig(
      apiUrl: api.isNotEmpty
          ? api
          : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android
                ? 'http://10.0.2.2:3000/api/v1'
                : 'http://localhost:3000/api/v1'),
      mapStyleUrl: const String.fromEnvironment(
        'MAP_STYLE_URL',
        defaultValue: 'https://tiles.openfreemap.org/styles/liberty',
      ),
    );
  }

  final String apiUrl;
  final String mapStyleUrl;
}
