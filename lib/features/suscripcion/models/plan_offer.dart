import '../../../shared/models/json_values.dart';

class PlanOffer {
  const PlanOffer({
    required this.id,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.busquedasFotoMes,
    this.mensajesAgenteMes,
  });

  factory PlanOffer.fromJson(JsonObject json) => PlanOffer(
    id: requiredString(json, 'id'),
    nombre: requiredString(json, 'nombre'),
    descripcion: json['descripcion'] as String?,
    precio: numberValue(json['precioReferencial']) ?? 0,
    busquedasFotoMes: integerValue(json['busquedasFotoMes']),
    mensajesAgenteMes: integerValue(json['mensajesAgenteMes']),
  );

  final String id, nombre;
  final String? descripcion;
  final double precio;
  final int? busquedasFotoMes, mensajesAgenteMes;

  bool get dePago => precio > 0;
  String get precioTexto => 'Bs ${precio.toStringAsFixed(2)}';
  String get descripcionClara {
    final text = descripcion?.trim();
    if (text != null && text.isNotEmpty) return text;
    return 'Más herramientas para buscar, cuidar y acompañar a tus mascotas.';
  }

  String cupo(String nombre, int? limite) {
    if (limite == null) return '$nombre sin límite durante el mes';
    if (limite == 0) return '$nombre no incluido';
    return '$limite $nombre al mes';
  }
}
