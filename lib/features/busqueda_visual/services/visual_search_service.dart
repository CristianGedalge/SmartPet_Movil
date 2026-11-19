import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../shared/services/api_client.dart';
import '../../../shared/models/json_values.dart';
import '../../mascotas/models/pet.dart';
import '../../mascotas/services/pets_service.dart';
import '../models/visual_search.dart';

class VisualSearchService {
  VisualSearchService(this.api);
  final ApiClient api;

  Future<List<Species>> species() async => (await PetsService(api).species())
      .where(
        (item) => ['perro', 'gato'].contains(item.nombre.trim().toLowerCase()),
      )
      .toList();

  Future<VisualSearchResult> search(
    int speciesId,
    List<UploadPhoto> photos,
  ) async {
    if (photos.isEmpty || photos.length > 5) {
      throw const ApiFailure('Selecciona entre 1 y 5 fotos.');
    }
    for (final photo in photos) {
      if (photo.bytes.isEmpty || photo.bytes.length > 5 * 1024 * 1024) {
        throw const ApiFailure('Cada foto debe pesar entre 1 byte y 5 MB.');
      }
    }
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${api.baseUrl}/busqueda-visual/avistamientos'),
    );
    request.fields['especieId'] = '$speciesId';
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
    return VisualSearchResult.fromJson(
      jsonObject(
        await api.send(request, timeout: const Duration(seconds: 180)),
      ),
    );
  }
}
