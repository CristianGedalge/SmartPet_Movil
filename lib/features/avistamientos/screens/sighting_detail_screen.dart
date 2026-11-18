import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';

import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../shared/widgets/location_map.dart';
import '../models/sighting.dart';
import '../services/sightings_service.dart';
import '../../mascotas/widgets/photo_picker.dart';
import 'sighting_form_screen.dart';
import '../../chat/widgets/contact_author_button.dart';
import '../../chat/services/chat_service.dart';

class SightingDetailScreen extends StatelessWidget {
  const SightingDetailScreen({
    super.key,
    required this.service,
    required this.id,
    required this.styleUrl,
    this.mapBuilder,
  });
  final SightingsService service;
  final String id, styleUrl;
  final Widget Function(LatLng point)? mapBuilder;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Avistamiento')),
    body: AsyncResource<Sighting>(
      load: () => service.find(id),
      builder: (_, sighting, reload) => _Detail(
        sighting: sighting,
        service: service,
        reload: reload,
        styleUrl: styleUrl,
        mapBuilder: mapBuilder,
      ),
    ),
  );
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.sighting,
    required this.service,
    required this.reload,
    required this.styleUrl,
    this.mapBuilder,
  });
  final Sighting sighting;
  final SightingsService service;
  final VoidCallback reload;
  final String styleUrl;
  final Widget Function(LatLng point)? mapBuilder;
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends State<_Detail> {
  bool _busy = false;
  String? _error;
  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close(bool cancel) async {
    await _run(() async {
      if (!await confirmAction(
            context,
            title: cancel ? '¿Cancelar avistamiento?' : '¿Cerrar avistamiento?',
            message: 'Dejará de mostrarse en Comunidad y no podrá editarse. Cerrar un reporte no confirma la identidad de la mascota.',
            confirmLabel: cancel ? 'Cancelar reporte' : 'Cerrar reporte',
            destructive: cancel,
          ) ||
          !mounted) {
        return;
      }
      await widget.service.close(widget.sighting.id, cancel: cancel);
      if (mounted) {
        showMessage(
          context,
          cancel ? 'Avistamiento cancelado.' : 'Avistamiento cerrado.',
        );
        widget.reload();
      }
    });
  }

  @override
  Widget build(BuildContext _) {
    final sighting = widget.sighting;
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              sighting.species?.nombre ?? 'Mascota vista',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(sighting.statusLabel)),
            ),
            Text('Visto: ${friendlyDate(context, sighting.seenAt)}'),
            if (!sighting.isMine && sighting.status == 'ACTIVO') ...[
              const SizedBox(height: 16),
              ContactAuthorButton(
                service: ChatService(widget.service.api),
                sightingId: sighting.id,
              ),
            ],
            const SizedBox(height: 16),
            Text(
              sighting.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(sighting.address),
            const SizedBox(height: 16),
            if (widget.mapBuilder != null)
              widget.mapBuilder!(LatLng(sighting.latitude, sighting.longitude))
            else
              LocationMap(
                styleUrl: widget.styleUrl,
                value: LatLng(sighting.latitude, sighting.longitude),
              ),
            const SizedBox(height: 20),
            if (sighting.editable)
              OutlinedButton.icon(
                onPressed: _busy
                    ? null
                    : () async {
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SightingFormScreen(
                              service: widget.service,
                              sighting: sighting,
                              styleUrl: widget.styleUrl,
                            ),
                          ),
                        );
                        if (saved == true && mounted) {
                          showMessage(context, 'Datos actualizados.');
                          widget.reload();
                        }
                      },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar datos'),
              ),
            const SizedBox(height: 20),
            const Text(
              'Sus fotografías',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final photo in sighting.photos)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      AnimalImage(url: photo.url),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              photo.isMain
                                  ? 'Foto principal'
                                  : 'Foto del avistamiento',
                            ),
                          ),
                          if (sighting.editable)
                            IconButton(
                              tooltip: 'Eliminar foto',
                              onPressed:
                                  _busy ||
                                      !sighting.editable ||
                                      sighting.photos.length <= 1
                                  ? null
                                  : () => _run(() async {
                                      if (!await confirmAction(
                                            context,
                                            title: '¿Eliminar fotografía?',
                                            message: 'El avistamiento debe conservar al menos una foto.',
                                            confirmLabel: 'Eliminar',
                                            destructive: true,
                                          ) ||
                                          !mounted) {
                                        return;
                                      }
                                      final pending = await widget.service
                                          .deletePhoto(sighting.id, photo.id);
                                      if (mounted) {
                                        showMessage(
                                          context,
                                          pending
                                              ? 'Foto eliminada. Su limpieza en el almacenamiento está pendiente.'
                                              : 'Foto eliminada.',
                                        );
                                        widget.reload();
                                      }
                                    }),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (sighting.editable)
              OutlinedButton.icon(
                onPressed:
                    _busy || !sighting.editable || sighting.photos.length >= 5
                    ? null
                    : () => _run(() async {
                        final photos = await pickPhotos(
                          context,
                          available: 5 - sighting.photos.length,
                        );
                        if (photos.isEmpty || !mounted) return;
                        await widget.service.addPhotos(sighting.id, photos);
                        if (mounted) {
                          showMessage(context, 'Fotos agregadas.');
                          widget.reload();
                        }
                      }),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Agregar fotografías'),
              ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              InlineMessage(_error!),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 20),
            if (sighting.editable) ...[
              FilledButton.icon(
                onPressed: _busy ? null : () => _close(false),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Cerrar avistamiento'),
              ),
              TextButton(
                onPressed: _busy ? null : () => _close(true),
                child: const Text('Cancelar avistamiento'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
