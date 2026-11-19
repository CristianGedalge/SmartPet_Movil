import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/pet.dart';

typedef PosterImageLoader = Future<Uint8List?> Function(Uri uri);

class PetPosterService {
  PetPosterService({PosterImageLoader? imageLoader})
    : _imageLoader = imageLoader ?? _download;

  static const width = 1080;
  static const height = 1350;
  static const _green = Color(0xFF008F73);
  static const _dark = Color(0xFF143B32);
  static const _muted = Color(0xFF61786E);
  static const _mint = Color(0xFFE2F7EE);
  static const _line = Color(0xFFD8E9E0);

  final PosterImageLoader _imageLoader;

  static Future<Uint8List?> _download(Uri uri) async {
    if (uri.scheme != 'https') return null;
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 ||
          response.bodyBytes.isEmpty ||
          response.bodyBytes.length > 10 * 1024 * 1024) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> generate(Pet pet) async {
    final photo = await _loadPhoto(pet.mainPhoto?.url);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(width.toDouble(), height.toDouble());

    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width.toDouble(), 190),
        const Radius.circular(0),
      ),
      Paint()..color = _mint,
    );
    _drawMark(canvas);
    _drawText(
      canvas,
      'SmartPet',
      const Offset(142, 55),
      fontSize: 46,
      weight: FontWeight.w900,
      color: _dark,
      maxWidth: 500,
    );
    _drawText(
      canvas,
      'FICHA DE MASCOTA',
      const Offset(742, 71),
      fontSize: 23,
      weight: FontWeight.w800,
      color: _green,
      maxWidth: 270,
      align: TextAlign.right,
    );

    const photoRect = Rect.fromLTWH(70, 225, 940, 590);
    canvas.drawRRect(
      RRect.fromRectAndRadius(photoRect, const Radius.circular(42)),
      Paint()..color = _mint,
    );
    if (photo == null) {
      _drawPhotoPlaceholder(canvas, photoRect);
    } else {
      _drawCoverImage(canvas, photo, photoRect);
    }

    _drawText(
      canvas,
      pet.nombre,
      const Offset(70, 855),
      fontSize: 68,
      weight: FontWeight.w900,
      color: _dark,
      maxWidth: 940,
      maxLines: 1,
    );

    var pillX = 70.0;
    final pills = <String>[
      pet.species?.nombre ?? 'Mascota',
      pet.sexLabel,
      pet.ageLabel,
    ];
    for (final value in pills) {
      pillX += _drawPill(canvas, value, Offset(pillX, 955)) + 14;
      if (pillX > 980) break;
    }

    canvas.drawLine(
      const Offset(70, 1045),
      const Offset(1010, 1045),
      Paint()
        ..color = _line
        ..strokeWidth = 3,
    );
    _drawDetail(
      canvas,
      label: 'Raza',
      value: _valueOrFallback(pet.razaNombre),
      x: 70,
      y: 1090,
    );
    _drawDetail(
      canvas,
      label: 'Color',
      value: _valueOrFallback(pet.color),
      x: 560,
      y: 1090,
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 1260, width.toDouble(), 90),
      Paint()..color = _dark,
    );
    _drawText(
      canvas,
      'Juntos, más cerca de casa.',
      const Offset(70, 1287),
      fontSize: 25,
      weight: FontWeight.w700,
      color: Colors.white,
      maxWidth: 940,
      align: TextAlign.center,
    );

    final picture = recorder.endRecording();
    final output = await picture.toImage(width, height);
    final data = await output.toByteData(format: ui.ImageByteFormat.png);
    output.dispose();
    photo?.dispose();
    if (data == null) {
      throw StateError('No pudimos crear el afiche. Inténtalo nuevamente.');
    }
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<ui.Image?> _loadPhoto(String? value) async {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null || !uri.hasAuthority) return null;
    final bytes = await _imageLoader(uri);
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1200);
      final frame = await codec.getNextFrame();
      codec.dispose();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static String _valueOrFallback(String? value) {
    final clean = value?.trim();
    return clean == null || clean.isEmpty ? 'Sin especificar' : clean;
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    required double fontSize,
    required FontWeight weight,
    required Color color,
    required double maxWidth,
    int maxLines = 2,
    TextAlign align = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: weight,
          height: 1.08,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  static void _drawMark(Canvas canvas) {
    final paint = Paint()..color = _green;
    canvas.drawCircle(const Offset(92, 105), 29, paint);
    canvas.drawCircle(const Offset(58, 70), 13, paint);
    canvas.drawCircle(const Offset(86, 58), 13, paint);
    canvas.drawCircle(const Offset(116, 64), 13, paint);
    canvas.drawCircle(const Offset(132, 92), 13, paint);
  }

  static void _drawPhotoPlaceholder(Canvas canvas, Rect rect) {
    final center = rect.center;
    final paint = Paint()..color = const Color(0xFF79BDA7);
    canvas.drawCircle(center.translate(0, 12), 58, paint);
    canvas.drawCircle(center.translate(-65, -48), 24, paint);
    canvas.drawCircle(center.translate(-22, -78), 24, paint);
    canvas.drawCircle(center.translate(28, -78), 24, paint);
    canvas.drawCircle(center.translate(70, -45), 24, paint);
  }

  static void _drawCoverImage(Canvas canvas, ui.Image image, Rect destination) {
    final sourceRatio = image.width / image.height;
    final destinationRatio = destination.width / destination.height;
    late Rect source;
    if (sourceRatio > destinationRatio) {
      final sourceWidth = image.height * destinationRatio;
      source = Rect.fromLTWH(
        (image.width - sourceWidth) / 2,
        0,
        sourceWidth,
        image.height.toDouble(),
      );
    } else {
      final sourceHeight = image.width / destinationRatio;
      source = Rect.fromLTWH(
        0,
        (image.height - sourceHeight) / 2,
        image.width.toDouble(),
        sourceHeight,
      );
    }
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(destination, const Radius.circular(42)),
    );
    canvas.drawImageRect(image, source, destination, Paint());
    canvas.restore();
  }

  static double _drawPill(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: const TextStyle(
          color: _green,
          fontSize: 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 250);
    final width = painter.width + 48;
    final rect = Rect.fromLTWH(offset.dx, offset.dy, width, 58);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(29)),
      Paint()..color = _mint,
    );
    painter.paint(canvas, offset.translate(24, 14));
    return width;
  }

  static void _drawDetail(
    Canvas canvas, {
    required String label,
    required String value,
    required double x,
    required double y,
  }) {
    _drawText(
      canvas,
      label.toUpperCase(),
      Offset(x, y),
      fontSize: 19,
      weight: FontWeight.w800,
      color: _green,
      maxWidth: 420,
      maxLines: 1,
    );
    _drawText(
      canvas,
      value,
      Offset(x, y + 35),
      fontSize: 31,
      weight: FontWeight.w700,
      color: _muted,
      maxWidth: 420,
      maxLines: 1,
    );
  }
}
