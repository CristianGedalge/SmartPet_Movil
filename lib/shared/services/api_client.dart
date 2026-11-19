import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status});
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.baseUrl, {http.Client? client})
    : _client = client ?? http.Client();
  final String baseUrl;
  final http.Client _client;
  String? token;
  void Function(String expiredToken)? onUnauthorized;

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = true,
  }) {
    final request = http.Request(
      method,
      Uri.parse('$baseUrl$path').replace(queryParameters: query),
    );
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return send(request, authenticated: authenticated);
  }

  Future<dynamic> send(
    http.BaseRequest request, {
    bool authenticated = true,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final capturedToken = authenticated ? token : null;
    if (authenticated && capturedToken == null) {
      throw const ApiFailure('Inicia sesión para continuar.', status: 401);
    }
    if (capturedToken != null) {
      request.headers['Authorization'] = 'Bearer $capturedToken';
    }
    request.headers['Accept'] = 'application/json';
    try {
      final response = await (() async => http.Response.fromStream(
        await _client.send(request),
      ))().timeout(timeout);
      dynamic data;
      try {
        data = response.body.isEmpty
            ? null
            : jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        if (response.statusCode < 400) {
          throw const ApiFailure('La API devolvió una respuesta no válida.');
        }
      }
      if (response.statusCode >= 400) {
        if (response.statusCode == 401 &&
            capturedToken != null &&
            token == capturedToken) {
          onUnauthorized?.call(capturedToken);
        }
        final message = data is Map ? data['message'] : null;
        throw ApiFailure(
          response.statusCode >= 500
              ? 'El servicio no está disponible. Intenta nuevamente.'
              : message is List
              ? message.join('\n')
              : message is String
              ? message
              : 'No se pudo completar la operación (${response.statusCode}).',
          status: response.statusCode,
        );
      }
      return data;
    } on TimeoutException {
      throw const ApiFailure(
        'La conexión tardó demasiado. Comprueba el resultado antes de volver a enviar.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        'No se pudo conectar. Revisa tu conexión e intenta nuevamente.',
      );
    }
  }

  void close() => _client.close();
}
