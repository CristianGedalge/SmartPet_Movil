import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Solicita una única posición por acción del usuario, sin seguimiento.
class LocationButton extends StatefulWidget {
  const LocationButton({super.key, required this.onLocated});

  final ValueChanged<Position> onLocated;

  @override
  State<LocationButton> createState() => _LocationButtonState();
}

class _LocationButtonState extends State<LocationButton> {
  bool _busy = false;
  String? _error;
  Future<bool> Function()? _openSettings;

  Future<void> _locate() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
      _openSettings = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _error = 'Activa la ubicación del dispositivo y vuelve a intentarlo.';
          if (!kIsWeb) _openSettings = Geolocator.openLocationSettings;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _error = kIsWeb
              ? 'Permite la ubicación en los permisos del sitio del navegador.'
              : 'Permite la ubicación en los ajustes de SmartPet y vuelve a intentarlo.';
          if (!kIsWeb) _openSettings = Geolocator.openAppSettings;
        });
        return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setState(() {
          _error = 'No se concedió el permiso. Puedes volver a intentarlo o tocar el mapa.';
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (mounted) widget.onLocated(position);
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _error = 'El GPS tardó demasiado. Reintenta en un lugar con mejor señal o toca el mapa.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudo obtener tu ubicación. Revisa el GPS y los permisos o toca el mapa.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _settings() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final opened = await _openSettings!();
      if (mounted && !opened) {
        setState(
          () => _error = 'Abre los ajustes del teléfono para habilitar la ubicación de SmartPet.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'No se pudieron abrir los ajustes. Habilita la ubicación desde los ajustes del teléfono.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextButton.icon(
        onPressed: _busy ? null : _locate,
        icon: const Icon(Icons.my_location_rounded),
        label: Text(_busy ? 'Buscando ubicación…' : 'Usar mi ubicación'),
      ),
      if (_error != null) ...[
        Text(
          _error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        if (_openSettings != null)
          TextButton.icon(
            onPressed: _busy ? null : _settings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Abrir ajustes'),
          ),
      ],
    ],
  );
}
