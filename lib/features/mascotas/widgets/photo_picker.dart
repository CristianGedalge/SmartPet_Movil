import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/services/api_client.dart';
import '../services/pets_service.dart';

Future<List<UploadPhoto>> pickPhotos(
  BuildContext context, {
  required int available,
  ImagePicker? imagePicker,
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
  if (source == null || !context.mounted) return [];
  try {
    final picker = imagePicker ?? ImagePicker();
    final files = source == ImageSource.camera
        ? [
            await picker.pickImage(
              source: source,
              imageQuality: 85,
              requestFullMetadata: false,
            ),
          ].whereType<XFile>().toList()
        : await picker.pickMultiImage(
            limit: available,
            imageQuality: 85,
            requestFullMetadata: false,
          );
    if (files.length > available) {
      throw ApiFailure('Selecciona como máximo $available fotos.');
    }
    return await Future.wait(files.map(UploadPhoto.read));
  } on PlatformException catch (error) {
    throw ApiFailure(switch (error.code) {
      'camera_access_denied' ||
      'camera_access_denied_without_prompt' ||
      'camera_access_restricted' => 'Permite el acceso a la cámara en los ajustes de SmartPet o elige una foto de la galería.',
      'photo_access_denied' ||
      'photo_access_denied_without_prompt' ||
      'photo_access_restricted' => 'Permite el acceso a tus fotos en los ajustes de SmartPet o toma una foto.',
      'already_active' => 'Ya hay un selector de fotos abierto. Ciérralo antes de volver a intentarlo.',
      _ => 'No se pudo abrir la cámara o la galería. Vuelve a intentarlo.',
    });
  } on ApiFailure {
    rethrow;
  } catch (_) {
    throw const ApiFailure(
      'No pudimos leer las fotos. Selecciónalas nuevamente.',
    );
  }
}
