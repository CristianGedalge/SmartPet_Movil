import 'package:flutter/material.dart';

import '../../../shared/controllers/paged_list_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../../mascotas/services/pets_service.dart';
import '../models/lost_alert.dart';
import '../services/alerts_service.dart';
import 'alert_form_screen.dart';
import 'alert_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({
    super.key,
    required this.service,
    required this.pets,
    required this.styleUrl,
  });
  final AlertsService service;
  final PetsService pets;
  final String styleUrl;
  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _mine = false;
  late final _public = PagedListController<LostAlert>(
    fetchPage: (limit, offset) =>
        widget.service.list(limit, offset, mine: false),
  );
  late final _own = PagedListController<LostAlert>(
    fetchPage: (limit, offset) =>
        widget.service.list(limit, offset, mine: true),
  );
  @override
  void initState() {
    super.initState();
    _public.refresh();
  }

  @override
  void dispose() {
    _public.dispose();
    _own.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AlertFormScreen(
          service: widget.service,
          pets: widget.pets,
          styleUrl: widget.styleUrl,
        ),
      ),
    );
    if (saved == true && mounted) {
      showMessage(context, 'Alerta publicada.');
      setState(() => _mine = true);
      await _own.refresh();
      await _public.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.campaign_outlined),
      label: const Text('Publicar alerta'),
    ),
    body: PagedListView<LostAlert>(
      controller: _mine ? _own : _public,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Volvamos a reunirlos',
            style: TextStyle(fontSize: 29, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text('Una comunidad atenta puede cambiar una historia.'),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final mine in [false, true])
                ChoiceChip(
                  label: Text(mine ? 'Mis alertas' : 'Comunidad'),
                  selected: _mine == mine,
                  onSelected: (_) {
                    setState(() => _mine = mine);
                    (mine ? _own : _public).refresh();
                  },
                ),
            ],
          ),
        ],
      ),
      empty: EmptyPanel(
        title: _mine ? 'Aún no publicaste alertas' : 'Sin alertas activas',
        message: _mine
            ? 'Si una de tus mascotas se pierde, puedes publicar una alerta aquí.'
            : 'Cuando se publique una alerta de extravío aparecerá en este espacio.',
        icon: Icons.campaign_outlined,
      ),
      itemBuilder: (context, alert) => AlertCard(
        alert: alert,
        onTap: () async {
          final ownContext = _mine;
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => AlertDetailScreen(
                id: alert.id,
                mine: ownContext,
                service: widget.service,
                pets: widget.pets,
                styleUrl: widget.styleUrl,
              ),
            ),
          );
          if (mounted) {
            await (ownContext ? _own : _public).refresh();
          }
        },
      ),
    ),
  );
}

class AlertCard extends StatelessWidget {
  const AlertCard({super.key, required this.alert, this.onTap});
  final LostAlert alert;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalImage(
          url: alert.pet.mainPhoto?.url,
          height: 190,
          label: 'Foto de ${alert.pet.nombre}',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              alert.pet.nombre,
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            Chip(label: Text(alert.status.label)),
          ],
        ),
        Text('Última vez vista: ${friendlyDate(context, alert.lostAt)}'),
        if (alert.description?.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              alert.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Ver ficha y ubicación →',
          style: TextStyle(
            color: Color(0xFF008F73),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
