import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import 'app_widgets.dart';
import 'location_button.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({
    super.key,
    required this.styleUrl,
    this.value,
    this.onChanged,
    this.selectionHint = 'Toca el mapa para indicar dónde se perdió.',
  });
  final String styleUrl;
  final String selectionHint;
  final LatLng? value;
  final ValueChanged<LatLng>? onChanged;
  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  MapLibreMapController? _controller;
  bool _ready = false;
  String? _error;
  Timer? _timer;
  int _retry = 0;
  Future<void> _drawing = Future<void>.value();
  @override
  void initState() {
    super.initState();
    _watchLoad();
  }

  void _watchLoad() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 25), () {
      if (mounted && !_ready) {
        setState(() => _error = 'El mapa no cargó. Revisa tu conexión.');
      }
    });
  }

  @override
  void didUpdateWidget(covariant LocationMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ready) _draw();
  }

  void _draw() {
    final controller = _controller;
    _drawing = _drawing
        .then((_) async {
          if (!mounted || !_ready || controller != _controller) return;
          await controller!.clearCircles();
          if (!mounted || controller != _controller || widget.value == null) {
            return;
          }
          await controller.addCircle(
            CircleOptions(
              geometry: widget.value,
              circleRadius: 10,
              circleColor: '#00B894',
              circleStrokeColor: '#FFFFFF',
              circleStrokeWidth: 3,
            ),
          );
        })
        .catchError((Object _) {
          if (mounted) {
            setState(
              () => _error =
                  'No se pudo actualizar el marcador. Vuelve a abrir el mapa.',
            );
          }
        });
  }

  Future<void> _center(LatLng point) async {
    final controller = _controller;
    if (!_ready || controller == null) return;
    try {
      await controller.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    } catch (_) {
      // La selecci?n se conserva aunque la vista est? cerr?ndose.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ready = false;
    _controller = null;
    // MapLibreMap owns and disposes its controller and native platform view.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supported =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!supported) {
      return const InlineMessage(
        'El mapa está disponible en Android, iOS y navegador.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                MapLibreMap(
                  key: ValueKey(_retry),
                  styleString: widget.styleUrl,
                  initialCameraPosition: CameraPosition(
                    target: widget.value ?? const LatLng(-16.5, -68.15),
                    zoom: widget.value == null ? 12 : 15,
                  ),
                  onMapCreated: (controller) {
                    _controller = controller;
                  },
                  onStyleLoadedCallback: () {
                    if (!mounted) return;
                    _timer?.cancel();
                    setState(() {
                      _ready = true;
                      _error = null;
                    });
                    _draw();
                    if (widget.value != null) _center(widget.value!);
                  },
                  onMapClick: widget.onChanged == null
                      ? null
                      : (_, point) => widget.onChanged!(point),
                  attributionEnabled: true,
                ),
                if (!_ready && _error == null)
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: Chip(label: Text('Cargando mapa…')),
                  ),
                if (_error != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: ErrorPanel(
                        message: _error!,
                        onRetry: () {
                          setState(() {
                            ++_retry;
                            _error = null;
                            _ready = false;
                            _controller = null;
                          });
                          _watchLoad();
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (widget.onChanged != null) ...[
          const SizedBox(height: 10),
          Text(
            widget.value == null
                ? widget.selectionHint
                : 'Ubicación seleccionada. Puedes moverla tocando otro punto.',
          ),
          LocationButton(
            onLocated: (position) {
              final point = LatLng(position.latitude, position.longitude);
              widget.onChanged?.call(point);
              _center(point);
            },
          ),
        ],
      ],
    );
  }
}
