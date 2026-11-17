import '../../../shared/models/json_values.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.rol,
    this.telefono,
    this.fotoUrl,
  });

  factory UserProfile.fromJson(JsonObject json) => UserProfile(
    id: requiredString(json, 'id'),
    nombre: requiredString(json, 'nombre'),
    apellido: requiredString(json, 'apellido'),
    email: requiredString(json, 'email'),
    rol: requiredString(json, 'rol'),
    telefono: json['telefono'] as String?,
    fotoUrl: json['fotoUrl'] as String?,
  );

  final String id, nombre, apellido, email, rol;
  final String? telefono, fotoUrl;
  bool get isCitizen => rol == 'CIUDADANO';
  String get fullName => '$nombre $apellido'.trim();
  String get initials =>
      '${String.fromCharCode(nombre.runes.first)}${String.fromCharCode(apellido.runes.first)}'
          .toUpperCase();
}
