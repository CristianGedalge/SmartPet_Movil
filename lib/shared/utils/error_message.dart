import 'dart:async';

import '../services/api_client.dart';

String userErrorMessage(
  Object? error, {
  String fallback = 'Ocurrió un problema. Intenta nuevamente.',
}) {
  if (error is ApiFailure && error.message.trim().isNotEmpty) {
    return error.message;
  }
  if (error is TimeoutException) {
    return 'La operación tardó demasiado. Revisa tu conexión e intenta nuevamente.';
  }
  return fallback;
}
