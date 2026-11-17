import '../../../shared/models/json_values.dart';
import '../../mascotas/models/pet.dart';

enum AlertStatus {
  active('ACTIVA', 'Activa'),
  resolved('RESUELTA', 'Resuelta'),
  cancelled('CANCELADA', 'Cancelada'),
  hidden('OCULTA', 'Oculta'),
  unknown('', 'No disponible');

  const AlertStatus(this.apiValue, this.label);
  final String apiValue, label;
  static AlertStatus parse(Object? value) => values.firstWhere(
    (state) => state.apiValue == value,
    orElse: () => unknown,
  );
}

class LostAlert {
  const LostAlert({
    required this.id,
    required this.petId,
    required this.pet,
    required this.status,
    required this.lostAt,
    required this.latitude,
    required this.longitude,
    this.description,
    this.resolvedAt,
  });
  factory LostAlert.fromJson(JsonObject json) => LostAlert(
    id: requiredString(json, 'id'),
    petId: requiredString(json, 'mascotaId'),
    pet: Pet.fromJson(jsonObject(json['mascota'])),
    status: AlertStatus.parse(json['estado']),
    lostAt: DateTime.parse(requiredString(json, 'fechaExtravio')),
    latitude:
        numberValue(json['latitud']) ??
        (throw const FormatException('Ubicación no disponible.')),
    longitude:
        numberValue(json['longitud']) ??
        (throw const FormatException('Ubicación no disponible.')),
    description: json['descripcion'] as String?,
    resolvedAt: json['fechaResolucion'] == null
        ? null
        : DateTime.parse(json['fechaResolucion'] as String),
  );
  final String id, petId;
  final Pet pet;
  final AlertStatus status;
  final DateTime lostAt;
  final double latitude, longitude;
  final String? description;
  final DateTime? resolvedAt;
  bool get isActive => status == AlertStatus.active;
}
