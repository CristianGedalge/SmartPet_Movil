import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../../../shared/widgets/location_map.dart';
import '../../mascotas/services/pets_service.dart';
import '../models/lost_alert.dart';
import '../services/alerts_service.dart';
import 'alert_form_screen.dart';
import '../../chat/widgets/contact_author_button.dart';
import '../../chat/services/chat_service.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({
    super.key,
    required this.id,
    required this.mine,
    required this.service,
    required this.pets,
    required this.styleUrl,
  });
  final String id, styleUrl;
  final bool mine;
  final AlertsService service;
  final PetsService pets;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Alerta de extravío')),
    body: AsyncResource<LostAlert>(
      load: () => service.find(id, mine: mine),
      builder: (_, alert, reload) => _Detail(
        alert: alert,
        owner: mine,
        service: service,
        pets: pets,
        styleUrl: styleUrl,
        reload: reload,
      ),
    ),
  );
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.alert,
    required this.owner,
    required this.service,
    required this.pets,
    required this.styleUrl,
    required this.reload,
  });
  final LostAlert alert;
  final bool owner;
  final AlertsService service;
  final PetsService pets;
  final String styleUrl;
  final VoidCallback reload;
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  bool _busy = false;
  String? _error;
  Future<void> _close(bool resolved) async {
    if (_busy) return;
    if (!await confirmAction(
          context,
          title: resolved ? '¿Ya volvió a casa?' : '¿Cancelar alerta?',
          message:
              'Esta acción cerrará la alerta y no podrá volver a editarse.',
          confirmLabel: resolved ? 'Marcar como resuelta' : 'Cancelar alerta',
          destructive: !resolved,
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.close(widget.alert.id, resolved: resolved);
      if (mounted) {
        showMessage(
          context,
          resolved
              ? 'Alerta resuelta. ¡Qué bueno que volvió!'
              : 'Alerta cancelada.',
        );
        widget.reload();
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimalImage(url: alert.pet.mainPhoto?.url, height: 260),
            const SizedBox(height: 20),
            Text(
              alert.pet.nombre,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(alert.status.label)),
            ),
            if (!widget.owner && alert.status == AlertStatus.active) ...[
              ContactAuthorButton(
                service: ChatService(widget.service.api),
                alertId: alert.id,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              [
                alert.pet.species?.nombre,
                alert.pet.razaNombre,
                alert.pet.sexLabel,
                alert.pet.ageLabel,
              ].whereType<String>().join(' · '),
            ),
            if (alert.pet.color?.isNotEmpty == true)
              Text('Color: ${alert.pet.color}'),
            const SizedBox(height: 18),
            Text('Última vez vista: ${friendlyDate(context, alert.lostAt)}'),
            if (alert.resolvedAt != null)
              Text('Resuelta: ${friendlyDate(context, alert.resolvedAt!)}'),
            if (alert.description?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  alert.description!,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            const SizedBox(height: 18),
            const Text(
              'Última ubicación conocida',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            LocationMap(
              styleUrl: widget.styleUrl,
              value: LatLng(alert.latitude, alert.longitude),
            ),
            if (widget.owner && alert.status == AlertStatus.active) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AlertFormScreen(
                              service: widget.service,
                              pets: widget.pets,
                              styleUrl: widget.styleUrl,
                              alert: alert,
                            ),
                          ),
                        );
                        if (saved == true && mounted) widget.reload();
                      },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar alerta'),
              ),
              FilledButton.icon(
                onPressed: _busy ? null : () => _close(true),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Ya volvió a casa'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _close(false),
                child: const Text('Cancelar alerta'),
              ),
            ],
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_error != null) InlineMessage(_error!),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
