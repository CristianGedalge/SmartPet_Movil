import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../shared/utils/error_message.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/pet.dart';
import '../services/pet_poster_service.dart';
import '../services/pet_poster_share_service.dart';

class PetPosterScreen extends StatefulWidget {
  const PetPosterScreen({
    super.key,
    required this.pet,
    this.posterService,
    this.shareService,
  });

  final Pet pet;
  final PetPosterService? posterService;
  final PetPosterShareService? shareService;

  @override
  State<PetPosterScreen> createState() => _PetPosterScreenState();
}

class _PetPosterScreenState extends State<PetPosterScreen> {
  late final PetPosterService _service;
  late final PetPosterShareService _shareService;
  final GlobalKey _shareButtonKey = GlobalKey();
  Uint8List? _poster;
  String? _error;
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    _service = widget.posterService ?? PetPosterService();
    _shareService = widget.shareService ?? PetPosterShareService();
    _generate();
  }

  Future<void> _generate() async {
    if (!_loading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await _service.generate(widget.pet);
      if (mounted) setState(() => _poster = result);
    } catch (error) {
      if (mounted) setState(() => _error = userErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _share() async {
    final poster = _poster;
    if (poster == null || _sharing) return;

    setState(() => _sharing = true);
    try {
      final renderBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;
      final result = await _shareService.share(
        bytes: poster,
        petName: widget.pet.nombre,
        sharePositionOrigin: origin,
      );
      if (mounted && result == PetPosterShareResult.unavailable) {
        showMessage(
          context,
          'No hay una aplicación disponible para compartir el afiche.',
        );
      }
    } catch (error, stackTrace) {
      debugPrint('No se pudo compartir el afiche: $error\n$stackTrace');
      if (mounted) {
        showMessage(
          context,
          'No se pudo compartir el afiche. Inténtalo nuevamente.',
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Afiche de mascota')),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Vista previa',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'El afiche se genera en tu dispositivo y no publica información personal.',
            ),
            const SizedBox(height: 18),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(10),
                child: _loading
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Generando afiche…'),
                          ],
                        ),
                      )
                    : _error != null
                    ? Center(child: InlineMessage(_error!))
                    : InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Center(
                          child: Semantics(
                            label: 'Afiche generado de ${widget.pet.nombre}',
                            image: true,
                            child: Image.memory(
                              _poster!,
                              key: const Key('pet-poster-preview'),
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            if (!_loading && _poster != null)
              const Text(
                'Afiche listo en formato PNG · 1080 × 1350 px',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: _shareButtonKey,
              onPressed: _loading || _poster == null || _sharing
                  ? null
                  : _share,
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
              label: Text(_sharing ? 'Preparando…' : 'Compartir o guardar'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _loading || _sharing ? null : _generate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Volver a generar'),
            ),
          ],
        ),
      ),
    ),
  );
}
