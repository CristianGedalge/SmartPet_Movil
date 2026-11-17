import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../../mascotas/models/pet.dart';
import '../../mascotas/services/pets_service.dart';
import '../models/sighting.dart';

class SightingsService {
  SightingsService(this.api);
  final ApiClient api;
  Future<List<Species>> species() async =>
      (await api.request('GET', '/especies') as List)
          .map((e) => Species.fromJson(jsonObject(e)))
          .toList();
  Future<List<Sighting>> list(
    int limit,
    int offset, {
    required bool mine,
  }) async => (await api.request(
    'GET',
    mine ? '/avistamientos/mis-avistamientos' : '/avistamientos',
    query: {'limit': '$limit', 'offset': '$offset'},
    authenticated: mine,
  ) as List).map((e) => Sighting.fromJson(jsonObject(e))).toList();
  Future<Sighting> find(String id) async => Sighting.fromJson(
    jsonObject(await api.request('GET', '/avistamientos/$id')),
  );
  Future<Sighting> create(
    Map<String, dynamic> data,
    List<UploadPhoto> photos,
  ) async => Sighting.fromJson(
    jsonObject(await _upload('/avistamientos', data, photos)),
  );
  Future<Sighting> update(String id, Map<String, dynamic> data) async =>
      Sighting.fromJson(
        jsonObject(
          await api.request('PATCH', '/avistamientos/$id', body: data),
        ),
      );
  Future<void> close(String id, {required bool cancel}) async {
    await api.request(
      'PATCH',
      '/avistamientos/$id/${cancel ? 'cancelar' : 'cerrar'}',
      body: {},
    );
  }

  Future<void> addPhotos(String id, List<UploadPhoto> photos) async {
    await _upload('/avistamientos/$id/fotos', {}, photos);
  }

  Future<bool> deletePhoto(String id, String photoId) async {
    final result = jsonObject(
      await api.request('DELETE', '/avistamientos/$id/fotos/$photoId'),
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
