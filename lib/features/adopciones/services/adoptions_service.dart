import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/adoption.dart';

class AdoptionsService {
  AdoptionsService(this.api);
  final ApiClient api;

  Future<List<AdoptionPublication>> list(int limit, int offset) async {
    final data = await api.request(
      'GET',
      '/adopciones',
      query: {'limit': '$limit', 'offset': '$offset'},
      authenticated: false,
    );
    try {
      if (data is! List) throw const FormatException();
      return data
          .map((item) => AdoptionPublication.fromJson(jsonObject(item)))
          .toList();
    } on FormatException {
      throw const ApiFailure(
        'No pudimos leer el catálogo de adopciones. Intenta nuevamente.',
      );
    } on TypeError {
      throw const ApiFailure(
        'No pudimos leer el catálogo de adopciones. Intenta nuevamente.',
      );
    }
  }

  Future<AdoptionPublication> find(String id) async {
    try {
      return AdoptionPublication.fromJson(
        jsonObject(
          await api.request(
            'GET',
            '/adopciones/${Uri.encodeComponent(id)}',
            authenticated: false,
          ),
        ),
      );
    } on ApiFailure catch (error) {
      if (error.status == 404) {
        throw const ApiFailure(
          'Esta publicación ya no está disponible. Vuelve al catálogo y actualízalo.',
          status: 404,
        );
      }
      rethrow;
    } on FormatException {
      throw const ApiFailure(
        'No pudimos leer la ficha de adopción. Intenta nuevamente.',
      );
    } on TypeError {
      throw const ApiFailure(
        'No pudimos leer la ficha de adopción. Intenta nuevamente.',
      );
    }
  }
}
