import 'package:flutter/material.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/async_resource.dart';
import '../models/pet.dart';
import '../services/pets_service.dart';
import '../widgets/photo_picker.dart';
import '../widgets/photo_selection.dart';

class PetFormScreen extends StatelessWidget {
  const PetFormScreen({
    super.key,
    required this.service,
    this.pet,
    this.photoPicker,
  });
  final PetsService service;
  final Pet? pet;
  final Future<List<UploadPhoto>> Function(BuildContext, int)? photoPicker;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(pet == null ? 'Registrar mascota' : 'Editar mascota'),
    ),
    body: AsyncResource<List<Species>>(
      load: service.species,
      builder: (_, species, _) => _PetForm(
        service: service,
        species: species,
        pet: pet,
        photoPicker: photoPicker,
      ),
    ),
  );
}

class _PetForm extends StatefulWidget {
  const _PetForm({
    required this.service,
    required this.species,
    this.pet,
    this.photoPicker,
  });
  final PetsService service;
  final List<Species> species;
  final Pet? pet;
  final Future<List<UploadPhoto>> Function(BuildContext, int)? photoPicker;
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
    if (_busy || _picking || _photos.length >= 5) return;
    setState(() {
      _picking = true;
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
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (_busy || _picking || !_form.currentState!.validate()) return;
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
      child: AbsorbPointer(
        absorbing: _busy || _picking,
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
                      (s) =>
                          DropdownMenuItem(value: s.id, child: Text(s.nombre)),
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
                  maxLength:
                      ['pesoKg', 'edadAproximadaMeses'].contains(entry.key)
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
                PhotoSelection(
                  photos: _photos,
                  busy: _busy,
                  picking: _picking,
                  onPick: _pick,
                  onRemove: (index) => setState(() {
                    _photos.removeAt(index);
                    _error = null;
                  }),
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
    ),
  );
}
