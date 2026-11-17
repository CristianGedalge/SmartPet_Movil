import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../services/pets_service.dart';

Future<List<UploadPhoto>> pickPhotos(
  BuildContext context, {
  required int available,
}) async {
  if (available <= 0) {
    showMessage(context, 'Puedes guardar un máximo de 5 fotos.');
    return [];
  }
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    useRootNavigator: false,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Tomar una foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return [];
  final picker = ImagePicker();
  final files = source == ImageSource.camera
      ? [
          await picker.pickImage(
            source: source,
            imageQuality: 85,
            requestFullMetadata: false,
          ),
        ].whereType<XFile>().toList()
      : await picker.pickMultiImage(
          imageQuality: 85,
          requestFullMetadata: false,
        );
  if (files.length > available) {
    throw 'Selecciona como máximo $available fotos.';
  }
  return Future.wait(files.map(UploadPhoto.read));
}
