import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:share_plus/share_plus.dart';

enum PetPosterShareResult { opened, dismissed, unavailable }

class PetPosterShareService {
  Future<PetPosterShareResult> share({
    required Uint8List bytes,
    required String petName,
    Rect? sharePositionOrigin,
  }) async {
    final temporaryDirectory = await Directory.systemTemp.createTemp(
      'smartpet-afiche-',
    );
    final fileName = fileNameFor(petName);
    final file = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}$fileName',
    );

    try {
      await file.writeAsBytes(bytes, flush: true);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png', name: fileName)],
          fileNameOverrides: [fileName],
          title: 'Afiche de $petName',
          subject: 'Afiche de $petName',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      _deleteLater(temporaryDirectory);

      return switch (result.status) {
        ShareResultStatus.success => PetPosterShareResult.opened,
        ShareResultStatus.dismissed => PetPosterShareResult.dismissed,
        ShareResultStatus.unavailable => PetPosterShareResult.unavailable,
      };
    } catch (_) {
      await _delete(temporaryDirectory);
      rethrow;
    }
  }

  void _deleteLater(Directory directory) {
    unawaited(
      Future<void>.delayed(
        const Duration(minutes: 5),
        () => _delete(directory),
      ),
    );
  }

  Future<void> _delete(Directory directory) async {
    try {
      if (await directory.exists()) await directory.delete(recursive: true);
    } on FileSystemException {
      // El sistema operativo también limpia su directorio temporal.
    }
  }

  String fileNameFor(String petName) {
    final normalized = petName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[áàäâ]'), 'a')
        .replaceAll(RegExp('[éèëê]'), 'e')
        .replaceAll(RegExp('[íìïî]'), 'i')
        .replaceAll(RegExp('[óòöô]'), 'o')
        .replaceAll(RegExp('[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp('[^a-z0-9]+'), '-')
        .replaceAll(RegExp('^-+|-+\$'), '');
    final suffix = normalized.isEmpty ? 'mascota' : normalized;
    return 'afiche-$suffix.png';
  }
}
