import 'package:flutter/material.dart';

import '../../../shared/controllers/paged_list_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/sighting.dart';
import '../services/sightings_service.dart';
import 'sighting_form_screen.dart';
import 'sighting_detail_screen.dart';

class SightingsScreen extends StatefulWidget {
  const SightingsScreen({
    super.key,
    required this.service,
    required this.styleUrl,
  });
  final SightingsService service;
  final String styleUrl;
  @override
  State<SightingsScreen> createState() => _SightingsScreenState();
}

class _SightingsScreenState extends State<SightingsScreen> {
  bool _mine = false;
  late final _public = PagedListController<Sighting>(
    fetchPage: (limit, offset) =>
        widget.service.list(limit, offset, mine: false),
  );
  late final _own = PagedListController<Sighting>(
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
        builder: (_) => SightingFormScreen(
          service: widget.service,
          styleUrl: widget.styleUrl,
        ),
      ),
    );
    if (saved == true && mounted) {
      showMessage(context, 'Avistamiento publicado.');
      setState(() => _mine = true);
      await _own.refresh();
      await _public.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _create,
      icon: const Icon(Icons.visibility_outlined),
      label: const Text('Reportar avistamiento'),
    ),
    body: PagedListView<Sighting>(
      controller: _mine ? _own : _public,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ojos atentos, hogares reunidos',
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
                  label: Text(mine ? 'Mis avistamientos' : 'Comunidad'),
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
        title: _mine
            ? 'Sin avistamientos propios'
            : 'Sin avistamientos activos',
        message: _mine
            ? 'Comparte fotos y el lugar si ves una mascota.'
            : 'Los reportes de la comunidad se muestran en este espacio.',
        icon: Icons.visibility_outlined,
      ),
      itemBuilder: (context, sighting) => SightingCard(
        sighting: sighting,
        onTap: () async {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => SightingDetailScreen(
                id: sighting.id,
                service: widget.service,
                styleUrl: widget.styleUrl,
              ),
            ),
          );
          if (mounted) {
            await Future.wait([_own.refresh(), _public.refresh()]);
          }
        },
      ),
    ),
  );
}

class SightingCard extends StatelessWidget {
  const SightingCard({super.key, required this.sighting, this.onTap});
  final Sighting sighting;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimalImage(
          url: sighting.photos.isEmpty ? null : sighting.photos.first.url,
          height: 190,
          label: 'Foto del avistamiento',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              sighting.species?.nombre ?? 'Mascota vista',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
            Chip(label: Text(sighting.statusLabel)),
          ],
        ),
        Text('Última vez vista: ${friendlyDate(context, sighting.seenAt)}'),
        if (sighting.description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              sighting.description,
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
