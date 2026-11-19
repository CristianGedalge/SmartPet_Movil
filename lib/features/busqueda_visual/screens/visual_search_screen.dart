import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/app_theme.dart';
import '../../../shared/utils/error_message.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../../mascotas/models/pet.dart';
import '../../mascotas/services/pets_service.dart';
import '../../mascotas/widgets/photo_picker.dart';
import '../../mascotas/widgets/photo_selection.dart';
import '../../avistamientos/screens/sighting_detail_screen.dart';
import '../../avistamientos/screens/sightings_screen.dart';
import '../../avistamientos/services/sightings_service.dart';
import '../models/visual_search.dart';
import '../services/visual_search_service.dart';

class VisualSearchScreen extends StatelessWidget {
  const VisualSearchScreen({
    super.key,
    required this.service,
    required this.sightings,
    required this.styleUrl,
    this.imagePicker,
  });
  final VisualSearchService service;
  final SightingsService sightings;
  final String styleUrl;
  final ImagePicker? imagePicker;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Buscar por foto')),
    body: AsyncResource<List<Species>>(
      load: service.species,
      builder: (_, species, reload) => _SearchForm(
        service: service,
        sightings: sightings,
        styleUrl: styleUrl,
        species: species,
        imagePicker: imagePicker,
      ),
    ),
  );
}

class _SearchForm extends StatefulWidget {
  const _SearchForm({
    required this.service,
    required this.sightings,
    required this.styleUrl,
    required this.species,
    this.imagePicker,
  });
  final VisualSearchService service;
  final SightingsService sightings;
  final List<Species> species;
  final String styleUrl;
  final ImagePicker? imagePicker;
  @override
  State<_SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<_SearchForm> {
  final List<UploadPhoto> _photos = [];
  int? _speciesId;
  bool _busy = false, _picking = false;
  String? _error;
  VisualSearchResult? _result;

  Future<void> _pick() async {
    if (_busy || _picking) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final selected = await pickPhotos(
        context,
        available: 5 - _photos.length,
        imagePicker: widget.imagePicker,
      );
      if (!mounted) return;
      if (selected.isNotEmpty) {
        setState(() {
          _photos.addAll(selected);
          _result = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = userErrorMessage(error));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _search() async {
    if (_busy || _picking) return;
    if (_speciesId == null || _photos.isEmpty) {
      setState(
        () => _error = 'Selecciona Perro o Gato y agrega al menos una foto.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await widget.service.search(_speciesId!, List.of(_photos));
      if (mounted) setState(() => _result = result);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = userErrorMessage(
            error,
            fallback: 'No pudimos buscar coincidencias. Intenta nuevamente.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Icon(
        Icons.image_search_rounded,
        color: AppColors.primary,
        size: 42,
      ),
      const SizedBox(height: 12),
      const Text(
        'Una foto puede acercarlos',
        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Compara fotos de tu mascota con los avistamientos de la comunidad. Usa imágenes de una sola mascota, bien iluminada y ocupando buena parte de la foto.',
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<int>(
        decoration: const InputDecoration(labelText: 'Especie de tu mascota'),
        items: widget.species
            .map(
              (item) =>
                  DropdownMenuItem(value: item.id, child: Text(item.nombre)),
            )
            .toList(),
        onChanged: _busy || _picking
            ? null
            : (value) => setState(() {
                _speciesId = value;
                _result = null;
                _error = null;
              }),
      ),
      if (widget.species.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'No hay especies disponibles en este momento. Intenta actualizar más tarde.',
          ),
        ),
      const SizedBox(height: 20),
      PhotoSelection(
        photos: _photos,
        busy: _busy,
        picking: _picking,
        onPick: _pick,
        onRemove: (index) => setState(() {
          _photos.removeAt(index);
          _result = null;
          _error = null;
        }),
      ),
      const SizedBox(height: 12),
      const Text(
        'Las fotos de esta consulta no se guardan en tu cuenta ni se publican.',
        style: TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _busy || _picking || widget.species.isEmpty ? null : _search,
        icon: const Icon(Icons.search_rounded),
        label: const Text('Buscar coincidencias'),
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: LoadingPanel(
            message: 'Comparando fotografías… La primera búsqueda puede tardar mientras se preparan los avistamientos.',
          ),
        ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: ErrorPanel(message: _error!, onRetry: _search),
        ),
      if (_result case final result?) ...[
        const SizedBox(height: 24),
        if (result.failedPhotos > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'No fue posible comparar ${result.failedPhotos} fotos de avistamientos. Los resultados pueden estar incompletos.',
            ),
          ),
        if (result.matches.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: EmptyPanel(
              title: 'No encontramos coincidencias',
              message: 'Ningún avistamiento tiene suficiente parecido con las fotos seleccionadas. Puedes probar con otras imágenes de tu mascota.',
              icon: Icons.image_search_outlined,
            ),
          ),
        if (result.matches.isNotEmpty) ...[
          Text(
            result.matches.length == 1
                ? '1 posible coincidencia'
                : '${result.matches.length} posibles coincidencias',
            style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          AppCard(child: Text(result.notice)),
        ],
        for (var i = 0; i < result.matches.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posible coincidencia ${i + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                SightingCard(
                  sighting: result.matches[i].sighting,
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SightingDetailScreen(
                        service: widget.sightings,
                        id: result.matches[i].sighting.id,
                        styleUrl: widget.styleUrl,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ],
  );
}
