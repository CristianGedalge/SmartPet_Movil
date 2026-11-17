import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/location_map.dart';
import '../../mascotas/models/pet.dart';
import '../../mascotas/services/pets_service.dart';
import '../../mascotas/screens/pets_screen.dart';
import '../models/lost_alert.dart';
import '../services/alerts_service.dart';

class AlertFormScreen extends StatefulWidget {
  const AlertFormScreen({
    super.key,
    required this.service,
    required this.pets,
    required this.styleUrl,
    this.alert,
    this.mapBuilder,
  });
  final AlertsService service;
  final PetsService pets;
  final String styleUrl;
  final LostAlert? alert;
  final Widget Function(LatLng? point, ValueChanged<LatLng> onChanged)?
  mapBuilder;
  @override
  State<AlertFormScreen> createState() => _AlertFormScreenState();
}

class _AlertFormScreenState extends State<AlertFormScreen> {
  late final TextEditingController _description;
  late DateTime _date;
  Pet? _pet;
  LatLng? _point;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final alert = widget.alert;
    _description = TextEditingController(text: alert?.description);
    _date = alert?.lostAt.toLocal() ?? DateTime.now();
    _pet = alert?.pet;
    if (alert != null) _point = LatLng(alert.latitude, alert.longitude);
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      useRootNavigator: false,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (selected == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      useRootNavigator: false,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (time == null || !mounted) return;
    setState(
      () => _date = DateTime(
        selected.year,
        selected.month,
        selected.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    if (_busy) return;
    if (_pet == null ||
        _point == null ||
        _date.isAfter(DateTime.now()) ||
        _description.text.length > 2000) {
      setState(
        () => _error = _pet == null
            ? 'Selecciona tu mascota.'
            : _point == null
            ? 'Marca en el mapa el último lugar donde la viste.'
            : _date.isAfter(DateTime.now())
            ? 'La fecha y hora no pueden ser futuras.'
            : 'La descripción debe tener como máximo 2000 caracteres.',
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final data = <String, dynamic>{
      if (widget.alert == null) 'mascotaId': _pet!.id,
      'descripcion': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'fechaExtravio': _date.toUtc().toIso8601String(),
      'latitud': double.parse(_point!.latitude.toStringAsFixed(8)),
      'longitud': double.parse(_point!.longitude.toStringAsFixed(8)),
    };
    try {
      if (widget.alert == null) {
        await widget.service.create(data);
      } else {
        await widget.service.update(widget.alert!.id, data);
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
        title: Text(widget.alert == null ? 'Publicar alerta' : 'Editar alerta'),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ayudemos a que vuelva.',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'La ficha y la ubicación serán públicas mientras la alerta esté activa. Evita incluir datos personales en la descripción.',
              ),
              const SizedBox(height: 24),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _pet?.nombre ?? 'Selecciona una mascota',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.alert == null)
                      TextButton.icon(
                        onPressed: () async {
                          final pet = await Navigator.push<Pet>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PetsScreen(
                                service: widget.pets,
                                select: true,
                              ),
                            ),
                          );
                          if (mounted && pet != null) {
                            setState(() => _pet = pet);
                          }
                        },
                        icon: const Icon(Icons.pets_rounded),
                        label: Text(
                          _pet == null
                              ? 'Elegir de mis mascotas'
                              : 'Cambiar mascota',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _chooseDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(
                  'Última vez vista: ${friendlyDate(context, _date)}',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _description,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '¿Qué ocurrió? (opcional)',
                  hintText:
                      'Señas particulares, zona o circunstancias del extravío…',
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Último lugar donde la viste',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
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
                  onChanged: (point) => setState(() => _point = point),
                ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                InlineMessage(_error!),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    _busy
                        ? 'Guardando…'
                        : widget.alert == null
                        ? 'Publicar alerta'
                        : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
