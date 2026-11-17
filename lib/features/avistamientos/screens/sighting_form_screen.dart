import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/location_map.dart';
import '../../mascotas/models/pet.dart';
import '../../mascotas/services/pets_service.dart';
import '../../mascotas/widgets/photo_picker.dart';
import '../models/sighting.dart';
import '../services/sightings_service.dart';

class SightingFormScreen extends StatefulWidget {
  const SightingFormScreen({
    super.key,
    required this.service,
    required this.styleUrl,
    this.sighting,
    this.mapBuilder,
    this.photoPicker,
  });
  final SightingsService service;
  final String styleUrl;
  final Sighting? sighting;
  final Widget Function(LatLng? point, ValueChanged<LatLng> onChanged)?
  mapBuilder;
  final Future<List<UploadPhoto>> Function(BuildContext context, int available)?
  photoPicker;
  @override
  State<SightingFormScreen> createState() => _SightingFormScreenState();
}

class _SightingFormScreenState extends State<SightingFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _description, _address;
  late DateTime _date;
  int? _speciesId;
  LatLng? _point;
  List<Species> _species = [];
  final List<UploadPhoto> _photos = [];
  bool _loading = true, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final value = widget.sighting;
    _description = TextEditingController(text: value?.description);
    _address = TextEditingController(text: value?.address);
    _date = value?.seenAt.toLocal() ?? DateTime.now();
    _speciesId = value?.speciesId;
    if (value != null) _point = LatLng(value.latitude, value.longitude);
    _loadSpecies();
  }

  Future<void> _loadSpecies() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final species = await widget.service.species();
      if (mounted) setState(() => _species = species);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: _date,
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      useRootNavigator: false,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null || !mounted) return;
    setState(
      () => _date = DateTime(
        day.year,
        day.month,
        day.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final available = 5 - _photos.length;
      final photos = widget.photoPicker != null
          ? await widget.photoPicker!(context, available)
          : await pickPhotos(context, available: available);
      if (mounted) setState(() => _photos.addAll(photos));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (_point == null ||
        _date.isAfter(DateTime.now()) ||
        (widget.sighting == null && _photos.isEmpty)) {
      setState(
        () => _error = _point == null
            ? 'Marca dónde viste a la mascota en el mapa.'
            : _date.isAfter(DateTime.now())
            ? 'La fecha y hora no pueden ser futuras.'
            : 'Agrega al menos una foto.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'especieId': _speciesId,
      'descripcion': _description.text.trim(),
      'direccion': _address.text.trim(),
      'fechaAvistamiento': _date.toUtc().toIso8601String(),
      'latitud': double.parse(_point!.latitude.toStringAsFixed(8)),
      'longitud': double.parse(_point!.longitude.toStringAsFixed(8)),
    };
    try {
      if (widget.sighting == null) {
        await widget.service.create(data, _photos);
      } else {
        await widget.service.update(widget.sighting!.id, data);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sighting == null
              ? 'Reportar avistamiento'
              : 'Editar avistamiento',
        ),
      ),
      body: _loading
          ? const LoadingPanel()
          : _species.isEmpty
          ? ErrorPanel(
              message: _error ?? 'No hay especies disponibles.',
              onRetry: _loadSpecies,
            )
          : AbsorbPointer(
              absorbing: _busy,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '¿Viste una mascota?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Comparte fotos y el lugar donde la viste. El reporte y su ubicación serán públicos mientras esté activo. Evita incluir datos personales.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        initialValue: _species.any((e) => e.id == _speciesId)
                            ? _speciesId
                            : null,
                        decoration: const InputDecoration(labelText: 'Especie'),
                        items: _species
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _speciesId = value),
                        validator: (value) =>
                            value == null ? 'Selecciona una especie.' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _description,
                        maxLength: 2000,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          hintText:
                              'Aspecto, señas particulares y qué observaste...',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Describe la mascota que viste.'
                            : value.trim().length > 2000
                            ? 'Máximo 2000 caracteres.'
                            : null,
                      ),
                      TextFormField(
                        controller: _address,
                        maxLength: 255,
                        decoration: const InputDecoration(
                          labelText: 'Referencia del lugar',
                          hintText: 'Barrio, calle o punto de referencia',
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Escribe una referencia del lugar.'
                            : value.trim().length > 255
                            ? 'Máximo 255 caracteres.'
                            : null,
                      ),
                      OutlinedButton.icon(
                        onPressed: _chooseDate,
                        icon: const Icon(Icons.event_outlined),
                        label: Text('Visto: ${friendlyDate(context, _date)}'),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Lugar del avistamiento',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (widget.mapBuilder != null)
                        widget.mapBuilder!(
                          _point,
                          (point) => setState(() => _point = point),
                        )
                      else
                        LocationMap(
                          styleUrl: widget.styleUrl,
                          value: _point,
                          selectionHint: 'Toca el mapa para indicar dónde viste a la mascota.',
                          onChanged: (point) => setState(() => _point = point),
                        ),
                      if (widget.sighting == null) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Fotos de la mascota (1-5)',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        for (var i = 0; i < _photos.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              children: [
                                Image.memory(
                                  Uint8List.fromList(_photos[i].bytes),
                                  height: 150,
                                  errorBuilder: (_, error, stack) =>
                                      const Icon(Icons.pets),
                                ),
                                TextButton(
                                  onPressed: () {
                                    final index = i;
                                    setState(() => _photos.removeAt(index));
                                  },
                                  child: Text('Quitar foto ${i + 1}'),
                                ),
                              ],
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: _photos.length >= 5 ? null : _pick,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Agregar fotos'),
                        ),
                      ],
                      if (_error != null) InlineMessage(_error!),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _busy ? null : _save,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Text(
                            _busy
                                ? 'Guardando...'
                                : widget.sighting == null
                                ? 'Publicar avistamiento'
                                : 'Guardar cambios',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    ),
  );
}
