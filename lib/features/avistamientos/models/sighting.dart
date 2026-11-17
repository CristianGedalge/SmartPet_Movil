import '../../../shared/models/json_values.dart';
import '../../mascotas/models/pet.dart';

class Sighting {
  Sighting.fromJson(JsonObject json)
    : id = requiredString(json, 'id'),
      speciesId = integerValue(json['especieId']) ?? 0,
      species = json['especie'] == null
          ? null
          : Species.fromJson(jsonObject(json['especie'])),
      description = requiredString(json, 'descripcion'),
      address = requiredString(json, 'direccion'),
      seenAt = DateTime.parse(requiredString(json, 'fechaAvistamiento')),
      latitude =
          numberValue(json['latitud']) ??
          (throw const FormatException('Falta ubicación.')),
      longitude =
          numberValue(json['longitud']) ??
          (throw const FormatException('Falta ubicación.')),
      status = requiredString(json, 'estado'),
      isMine = json['esPropio'] == true,
      photos = List.unmodifiable(
        (json['fotos'] as List? ?? []).map(
          (e) => PetPhoto.fromJson(jsonObject(e)),
        ),
      );
  final String id, description, address, status;
  final int speciesId;
  final Species? species;
  final DateTime seenAt;
  final double latitude, longitude;
  final bool isMine;
  final List<PetPhoto> photos;
  bool get editable => isMine && status == 'ACTIVO';
  String get statusLabel => switch (status) {
    'ACTIVO' => 'Activo',
    'CERRADO' => 'Cerrado',
    'CANCELADO' => 'Cancelado',
    _ => status,
  };
}
