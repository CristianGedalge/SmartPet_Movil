import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../services/pets_service.dart';

class PhotoSelection extends StatelessWidget {
  const PhotoSelection({
    super.key,
    required this.photos,
    required this.onPick,
    required this.onRemove,
    this.busy = false,
    this.picking = false,
  });

  final List<UploadPhoto> photos;
  final VoidCallback onPick;
  final ValueChanged<int> onRemove;
  final bool busy, picking;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          children: [
            const Text(
              'Fotografías',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Semantics(
              liveRegion: true,
              child: Chip(label: Text('${photos.length}/5 fotos')),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text('Agrega al menos una foto donde se vea bien la mascota.'),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: busy || picking || photos.length >= 5 ? null : onPick,
          icon: picking
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            picking
                ? 'Preparando fotos…'
                : photos.length >= 5
                ? 'Límite de 5 fotos'
                : 'Agregar fotos',
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cámara o galería · JPG, PNG o WebP · Hasta 5 MB por foto',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        if (photos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (var i = 0; i < photos.length; i++)
                SizedBox(
                  width: 108,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          Uint8List.fromList(photos[i].bytes),
                          height: 94,
                          width: 108,
                          cacheWidth: 324,
                          fit: BoxFit.cover,
                          semanticLabel: 'Foto seleccionada ${i + 1}',
                          errorBuilder: (_, error, stack) => const SizedBox(
                            height: 94,
                            child: Center(
                              child: Text(
                                'Vista previa no disponible',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        i == 0 ? 'Foto principal' : 'Foto ${i + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                      IconButton(
                        tooltip: 'Quitar foto ${i + 1}',
                        onPressed: busy || picking ? null : () => onRemove(i),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );
}
