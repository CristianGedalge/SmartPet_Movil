import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/lost_alert.dart';

class AlertsService {
  AlertsService(this.api);
  final ApiClient api;
  static const _path = '/alertas-extravio';
  Future<List<LostAlert>> list(
    int limit,
    int offset, {
    required bool mine,
  }) async => (await api.request(
    'GET',
    mine ? '$_path/mis-alertas' : _path,
    query: {'limit': '$limit', 'offset': '$offset'},
    authenticated: mine,
  ) as List).map((e) => LostAlert.fromJson(jsonObject(e))).toList();
  Future<LostAlert> find(String id, {required bool mine}) async =>
      LostAlert.fromJson(
        jsonObject(await api.request('GET', '$_path/$id', authenticated: mine)),
      );
  Future<void> create(Map<String, dynamic> data) async {
    await api.request('POST', _path, body: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await api.request('PATCH', '$_path/$id', body: data);
  }

  Future<void> close(String id, {required bool resolved}) async {
    await api.request(
      'PATCH',
      '$_path/$id/${resolved ? 'resolver' : 'cancelar'}',
      body: {},
    );
  }
}
