import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/pet.dart';

class UploadPhoto {
  const UploadPhoto(this.bytes, this.mime, this.filename);
  final List<int> bytes;
  final String mime, filename;
  static Future<UploadPhoto> read(XFile file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const ApiFailure('Cada foto debe pesar como máximo 5 MB.');
    }
    final bytes = await file.readAsBytes();
    String? mime;
    String? extension;
    if (bytes.length >= 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255) {
      mime = 'image/jpeg';
      extension = 'jpg';
    } else if (bytes.length >= 8 &&
        [
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
        ].asMap().entries.every((e) => bytes[e.key] == e.value)) {
      mime = 'image/png';
      extension = 'png';
    } else if (bytes.length >= 12 &&
        String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
        String.fromCharCodes(bytes.skip(8).take(4)) == 'WEBP') {
      mime = 'image/webp';
      extension = 'webp';
    }
    if (mime == null) {
      throw const ApiFailure(
        'Selecciona fotos JPG, PNG o WebP. El formato HEIC no es compatible.',
      );
    }
    return UploadPhoto(bytes, mime, 'mascota.$extension');
  }
}

class PetsService {
  PetsService(this.api);
  final ApiClient api;
  Future<List<Species>> species() async =>
      (await api.request('GET', '/especies') as List)
          .map((e) => Species.fromJson(jsonObject(e)))
          .toList();
  Future<List<Pet>> mine(int limit, int offset) async => (await api.request(
    'GET',
    '/mascotas/mis-mascotas',
    query: {'limit': '$limit', 'offset': '$offset'},
  ) as List).map((e) => Pet.fromJson(jsonObject(e))).toList();
  Future<Pet> find(String id) async =>
      Pet.fromJson(jsonObject(await api.request('GET', '/mascotas/$id')));
  Future<Pet> create(
    Map<String, dynamic> data,
    List<UploadPhoto> photos,
  ) async => Pet.fromJson(jsonObject(await _upload('/mascotas', data, photos)));
  Future<Pet> update(String id, Map<String, dynamic> data) async =>
      Pet.fromJson(
        jsonObject(await api.request('PATCH', '/mascotas/$id', body: data)),
      );
  Future<void> remove(String id) async {
    await api.request('DELETE', '/mascotas/$id');
  }

  Future<void> addPhotos(String id, List<UploadPhoto> photos) async {
    await _upload('/mascotas/$id/fotos', {}, photos);
  }

  Future<bool> deletePhoto(String id, String photoId) async {
    final result = jsonObject(
      await api.request('DELETE', '/mascotas/$id/fotos/$photoId'),
    );
    return result['limpiezaPendiente'] == true;
  }

  Future<dynamic> _upload(
    String path,
    Map<String, dynamic> data,
    List<UploadPhoto> photos,
  ) {
    if (photos.isEmpty || photos.length > 5) {
      throw const ApiFailure('Selecciona entre 1 y 5 fotos.');
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${api.baseUrl}$path'),
    );
    data.forEach((key, value) {
      if (value != null) request.fields[key] = '$value';
    });
    for (final photo in photos) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'fotos',
          photo.bytes,
          filename: photo.filename,
          contentType: MediaType.parse(photo.mime),
        ),
      );
    }
    return api.send(request);
  }
}
