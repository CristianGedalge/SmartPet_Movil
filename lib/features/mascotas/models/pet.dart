import '../../../shared/models/json_values.dart';

class Species {
  const Species({required this.id, required this.nombre});
  factory Species.fromJson(JsonObject json) => Species(
    id: integerValue(json['id']) ?? 0,
    nombre: requiredString(json, 'nombre'),
  );
  final int id;
  final String nombre;
}

class PetPhoto {
  const PetPhoto({required this.id, required this.url, required this.isMain});
  factory PetPhoto.fromJson(JsonObject json) => PetPhoto(
    id: requiredString(json, 'id'),
    url: requiredString(json, 'url'),
    isMain: json['esPrincipal'] == true,
  );
  final String id, url;
  final bool isMain;
}

class Pet {
  const Pet({
    required this.id,
    required this.nombre,
    required this.active,
    required this.photos,
    this.species,
    this.razaNombre,
    this.sexo,
    this.color,
    this.pesoKg,
    this.edadMeses,
  });

  factory Pet.fromJson(JsonObject json) {
    final photoList =
        (json['fotos'] as List?)
            ?.map((item) => PetPhoto.fromJson(jsonObject(item)))
            .toList() ??
        <PetPhoto>[];
    final main = json['fotoPrincipal'];
    if (photoList.isEmpty && main != null) {
      final photo = jsonObject(main);
      photoList.add(
        PetPhoto(
          id: requiredString(photo, 'id'),
          url: requiredString(photo, 'url'),
          isMain: true,
        ),
      );
    }
    return Pet(
      id: requiredString(json, 'id'),
      nombre: requiredString(json, 'nombre'),
      active: json['estado'] != false,
      photos: List.unmodifiable(photoList),
      species: json['especie'] == null
          ? null
          : Species.fromJson(jsonObject(json['especie'])),
      razaNombre: json['razaNombre'] as String?,
      sexo: json['sexo'] as String?,
      color: json['color'] as String?,
      pesoKg: numberValue(json['pesoKg']),
      edadMeses: integerValue(json['edadAproximadaMeses']),
    );
  }

  final String id, nombre;
  final bool active;
  final List<PetPhoto> photos;
  final Species? species;
  final String? razaNombre, sexo, color;
  final double? pesoKg;
  final int? edadMeses;

  PetPhoto? get mainPhoto => photos.isEmpty
      ? null
      : photos.firstWhere((photo) => photo.isMain, orElse: () => photos.first);
  String get sexLabel => switch (sexo) {
    'MACHO' => 'Macho',
    'HEMBRA' => 'Hembra',
    _ => 'Sin especificar',
  };
  String get ageLabel {
    final months = edadMeses;
    if (months == null) return 'Edad sin especificar';
    if (months < 12) return '$months ${months == 1 ? 'mes' : 'meses'}';
    final years = months ~/ 12;
    return '$years ${years == 1 ? 'año' : 'años'}';
  }
}
