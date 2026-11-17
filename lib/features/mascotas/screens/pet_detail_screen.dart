import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../models/pet.dart';
import '../services/pets_service.dart';
import '../widgets/photo_picker.dart';
import 'pet_form_screen.dart';

class PetDetailScreen extends StatelessWidget {
  const PetDetailScreen({super.key, required this.service, required this.id});
  final PetsService service;
  final String id;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ficha de mascota')),
    body: AsyncResource<Pet>(
      load: () => service.find(id),
      builder: (_, pet, reload) =>
          _Detail(pet: pet, service: service, reload: reload),
    ),
  );
}

class _Detail extends StatefulWidget {
  const _Detail({
    required this.pet,
    required this.service,
    required this.reload,
  });
  final Pet pet;
  final PetsService service;
  final VoidCallback reload;
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

  @override
  Widget build(BuildContext _) {
    final pet = widget.pet;
    return PopScope(
      canPop: !_busy,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimalImage(url: pet.mainPhoto?.url, height: 270),
            const SizedBox(height: 20),
            Text(
              pet.nombre,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              '${pet.species?.nombre ?? 'Mascota'} · ${pet.sexLabel} · ${pet.ageLabel}',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Raza: ${pet.razaNombre ?? 'Sin especificar'}'),
                  const SizedBox(height: 8),
                  Text('Color: ${pet.color ?? 'Sin especificar'}'),
                  const SizedBox(height: 8),
                  Text(
                    'Peso: ${pet.pesoKg == null ? 'Sin especificar' : '${pet.pesoKg} kg'}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final saved = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PetFormScreen(service: widget.service, pet: pet),
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
            for (final photo in pet.photos)
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
                                  : 'Foto de ${pet.nombre}',
                            ),
                          ),
                          IconButton(
                            tooltip: 'Eliminar foto',
                            onPressed: _busy || pet.photos.length <= 1
                                ? null
                                : () => _run(() async {
                                    if (!await confirmAction(
                                          context,
                                          title: '¿Eliminar fotografía?',
                                          message: 'La mascota debe conservar al menos una foto.',
                                          confirmLabel: 'Eliminar',
                                          destructive: true,
                                        ) ||
                                        !mounted) {
                                      return;
                                    }
                                    final pending = await widget.service
                                        .deletePhoto(pet.id, photo.id);
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
            OutlinedButton.icon(
              onPressed: _busy || pet.photos.length >= 5
                  ? null
                  : () => _run(() async {
                      final photos = await pickPhotos(
                        context,
                        available: 5 - pet.photos.length,
                      );
                      if (photos.isEmpty) return;
                      await widget.service.addPhotos(pet.id, photos);
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
            TextButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                      if (!await confirmAction(
                            context,
                            title: '¿Desactivar mascota?',
                            message: 'Se quitará de tu lista y sus alertas dejarán de mostrarse públicamente. Se conservará su historial.',
                            confirmLabel: 'Desactivar',
                            destructive: true,
                          ) ||
                          !mounted) {
                        return;
                      }
                      await widget.service.remove(pet.id);
                      if (mounted) {
                        showMessage(context, 'Mascota desactivada.');
                        Navigator.pop(context);
                      }
                    }),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Desactivar mascota'),
            ),
          ],
        ),
      ),
    );
  }
}
