import '../../../shared/models/json_values.dart';
import '../../suscripcion/models/plan_usage.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
    this.telefono,
    this.fotoUrl,
    this.suscripcion,
  });

  factory UserProfile.fromJson(JsonObject json) => UserProfile(
    id: requiredString(json, 'id'),
    nombre: requiredString(json, 'nombre'),
    apellido: requiredString(json, 'apellido'),
    email: requiredString(json, 'email'),
    rol: requiredString(json, 'rol'),
    telefono: json['telefono'] as String?,
    fotoUrl: json['fotoUrl'] as String?,
    suscripcion: json['suscripcion'] == null
        ? null
        : PlanUsage.fromJson(jsonObject(json['suscripcion'])),
  );

  final String id, nombre, apellido, email, rol;
  final String? telefono, fotoUrl;
  final PlanUsage? suscripcion;
  bool get isCitizen => rol == 'CIUDADANO';
  String get fullName => '$nombre $apellido'.trim();
  String get initials =>
      '${String.fromCharCode(nombre.runes.first)}${String.fromCharCode(apellido.runes.first)}'
          .toUpperCase();
}
