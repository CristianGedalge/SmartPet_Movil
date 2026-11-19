import '../../../shared/models/json_values.dart';

class PlanUsage {
  const PlanUsage({
    required this.plan,
    this.planId,
    required this.estado,
    required this.inicio,
    required this.busquedasFotoUsadas,
    required this.mensajesAgenteUsados,
    this.fin,
    this.busquedasFotoMes,
    this.mensajesAgenteMes,
  });

  factory PlanUsage.fromJson(JsonObject json) => PlanUsage(
    plan: requiredString(json, 'plan'),
    planId: json['planId'] as String?,
    estado: requiredString(json, 'estado'),
    inicio: DateTime.parse(requiredString(json, 'inicio')),
    fin: json['fin'] == null
        ? null
        : DateTime.parse(requiredString(json, 'fin')),
    busquedasFotoMes: integerValue(json['busquedasFotoMes']),
    busquedasFotoUsadas: integerValue(json['busquedasFotoUsadas']) ?? 0,
    mensajesAgenteMes: integerValue(json['mensajesAgenteMes']),
    mensajesAgenteUsados: integerValue(json['mensajesAgenteUsados']) ?? 0,
  );

  final String plan, estado;
  final String? planId;
  final DateTime inicio;
  final DateTime? fin;
  final int? busquedasFotoMes, mensajesAgenteMes;
  final int busquedasFotoUsadas, mensajesAgenteUsados;

  bool get activa => estado == 'ACTIVA';
  bool get puedeBuscar => _permite(busquedasFotoMes, busquedasFotoUsadas);
  bool get puedeAgente => _permite(mensajesAgenteMes, mensajesAgenteUsados);

  bool _permite(int? limite, int usado) =>
      activa && (limite == null || usado < limite);

  String textoBusqueda() => _texto(
    puedeBuscar,
    busquedasFotoMes,
    busquedasFotoUsadas,
    'búsquedas por foto',
  );

  String textoAgente() => _texto(
    puedeAgente,
    mensajesAgenteMes,
    mensajesAgenteUsados,
    'mensajes del agente',
  );

  String _texto(bool permitido, int? limite, int usado, String nombre) {
    if (!activa) {
      return estado == 'VENCIDA'
          ? 'Tu suscripción venció. Elige un plan para renovarla.'
          : 'No tienes una suscripción activa.';
    }
    if (!permitido) return 'Alcanzaste el cupo mensual de $nombre.';
    if (limite == null) return '$nombre: sin tope este mes.';
    return '$nombre: ${limite - usado} de $limite este mes.';
  }

  String? get vence {
    final date = fin?.toLocal();
    if (date == null) return null;
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}
