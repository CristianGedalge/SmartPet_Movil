import '../../../shared/models/json_values.dart';
import '../../mascotas/models/pet.dart';

class AdoptionEstablishment {
  AdoptionEstablishment.fromJson(JsonObject json)
    : name = requiredString(json, 'nombre'),
      type = requiredString(json, 'tipo'),
      address = requiredString(json, 'direccion'),
      phone = requiredString(json, 'telefono'),
      hours = json['horarioAtencion'] as String?;
  final String name, type, address, phone;
  final String? hours;
  String get typeLabel => type == 'VETERINARIA' ? 'Veterinaria' : 'Refugio';
}

class AdoptionPublication {
  AdoptionPublication.fromJson(JsonObject json)
    : id = requiredString(json, 'id'),
      description = requiredString(json, 'descripcion'),
      requirements = json['requisitos'] as String?,
      pet = Pet.fromJson(jsonObject(json['mascota'])),
      establishment = AdoptionEstablishment.fromJson(
        jsonObject(json['establecimiento']),
      );
  final String id, description;
  final String? requirements;
  final Pet pet;
  final AdoptionEstablishment establishment;
}
