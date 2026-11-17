typedef JsonObject = Map<String, dynamic>;

double? numberValue(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
int? integerValue(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

JsonObject jsonObject(Object? value) {
  if (value is Map<String, dynamic>) return value;
  throw const FormatException(
    'La respuesta del servidor no tiene el formato esperado.',
  );
}

String requiredString(JsonObject json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) return value;
  throw const FormatException('La respuesta del servidor está incompleta.');
}
