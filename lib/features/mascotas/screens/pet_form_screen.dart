import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../models/pet.dart';
import '../services/pets_service.dart';
import '../widgets/photo_picker.dart';

class PetFormScreen extends StatelessWidget {
  const PetFormScreen({super.key, required this.service, this.pet});
  final PetsService service;
  final Pet? pet;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(pet == null ? 'Registrar mascota' : 'Editar mascota'),
    ),
    body: AsyncResource<List<Species>>(
      load: service.species,
      builder: (_, species, _) =>
          _PetForm(service: service, species: species, pet: pet),
    ),
  );
}

class _PetForm extends StatefulWidget {
  const _PetForm({required this.service, required this.species, this.pet});
  final PetsService service;
  final List<Species> species;
  final Pet? pet;
  @override
  State<_PetForm> createState() => _PetFormState();
}

class _PetFormState extends State<_PetForm> {
  final _form = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;
  int? _species;
  String? _sex;
  bool _busy = false, _picking = false;
  String? _error;
  final List<UploadPhoto> _photos = [];
  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    _species = pet?.species?.id;
    _sex = pet?.sexo ?? 'DESCONOCIDO';
    _fields = {
      'nombre': TextEditingController(text: pet?.nombre),
      'razaNombre': TextEditingController(text: pet?.razaNombre),
      'color': TextEditingController(text: pet?.color),
      'pesoKg': TextEditingController(text: pet?.pesoKg?.toString()),
      'edadAproximadaMeses': TextEditingController(
        text: pet?.edadMeses?.toString(),
      ),
    };
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final photos = await pickPhotos(context, available: 5 - _photos.length);
      if (mounted) setState(() => _photos.addAll(photos));
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (widget.pet == null && _photos.isEmpty) {
      setState(() => _error = 'Agrega al menos una foto.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final data = <String, dynamic>{
      'nombre': _fields['nombre']!.text.trim(),
      'especieId': _species,
      'sexo': _sex,
    };
    for (final key in [
      'razaNombre',
      'color',
      'pesoKg',
      'edadAproximadaMeses',
    ]) {
      final value = _fields[key]!.text.trim();
      data[key] = value.isEmpty
          ? null
          : key == 'pesoKg'
          ? double.parse(value.replaceAll(',', '.'))
          : key == 'edadAproximadaMeses'
          ? int.parse(value)
          : value;
    }
    try {
      if (widget.pet == null) {
        await widget.service.create(data, _photos);
      } else {
        await widget.service.update(widget.pet!.id, data);
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
    canPop: !_busy && !_picking,
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cada mascota tiene su historia.',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text('Completa su ficha para tener sus datos a mano.'),
            const SizedBox(height: 24),
            DropdownButtonFormField<int>(
              initialValue: widget.species.any((s) => s.id == _species)
                  ? _species
                  : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Especie'),
              items: widget.species
                  .map(
                    (s) => DropdownMenuItem(value: s.id, child: Text(s.nombre)),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _species = value),
              validator: (v) => v == null ? 'Selecciona una especie.' : null,
            ),
            const SizedBox(height: 14),
            for (final entry in {
              'nombre': 'Nombre',
              'razaNombre': 'Raza (opcional)',
              'color': 'Color (opcional)',
              'pesoKg': 'Peso en kg (opcional)',
              'edadAproximadaMeses': 'Edad en meses (opcional)',
            }.entries) ...[
              TextFormField(
                controller: _fields[entry.key],
                enabled: !_busy,
                decoration: InputDecoration(labelText: entry.value),
                maxLength: ['pesoKg', 'edadAproximadaMeses'].contains(entry.key)
                    ? 12
                    : 100,
                keyboardType: entry.key == 'pesoKg'
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : entry.key == 'edadAproximadaMeses'
                    ? TextInputType.number
                    : TextInputType.text,
                validator: (v) {
                  final text = v?.trim() ?? '';
                  if (entry.key == 'nombre' && text.isEmpty) {
                    return 'Escribe su nombre.';
                  }
                  if (text.isEmpty) return null;
                  if (entry.key == 'pesoKg') {
                    final number = double.tryParse(text.replaceAll(',', '.'));
                    if (number == null ||
                        !number.isFinite ||
                        number < .01 ||
                        number > 9999.99 ||
                        !RegExp(r'^\d+([.,]\d{1,2})?$').hasMatch(text)) {
                      return 'Usa un peso entre 0,01 y 9999,99 (hasta 2 decimales).';
                    }
                  }
                  if (entry.key == 'edadAproximadaMeses') {
                    final number = int.tryParse(text);
                    if (number == null || number < 0 || number > 2147483647) {
                      return 'Escribe una edad válida en meses.';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              initialValue: _sex,
              decoration: const InputDecoration(labelText: 'Sexo'),
              items: const [
                DropdownMenuItem(
                  value: 'DESCONOCIDO',
                  child: Text('Sin especificar'),
                ),
                DropdownMenuItem(value: 'MACHO', child: Text('Macho')),
                DropdownMenuItem(value: 'HEMBRA', child: Text('Hembra')),
              ],
              onChanged: _busy ? null : (value) => _sex = value,
            ),
            if (widget.pet == null) ...[
              const SizedBox(height: 22),
              const Text(
                'Fotos · 1 a 5 · JPG, PNG o WebP · hasta 5 MB cada una',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < _photos.length; i++)
                    SizedBox(
                      width: 96,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              Uint8List.fromList(_photos[i].bytes),
                              height: 85,
                              width: 96,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Quitar foto',
                            onPressed: _busy
                                ? null
                                : () => setState(() => _photos.removeAt(i)),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _busy || _picking ? null : _pick,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_picking ? 'Preparando fotos…' : 'Agregar fotos'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              InlineMessage(_error!),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy || _picking ? null : _save,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_busy ? 'Guardando…' : 'Guardar mascota'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
