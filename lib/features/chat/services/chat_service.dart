import 'dart:math';

import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/chat.dart';

class ChatService {
  ChatService(this.api);
  final ApiClient api;
  static const path = '/chat/conversaciones';
  Future<Conversation> open({String? alertId, String? sightingId}) async =>
      Conversation.fromJson(
        jsonObject(
          await api.request(
            'POST',
            path,
            body: {'alertaId': ?alertId, 'avistamientoId': ?sightingId},
          ),
        ),
      );
  Future<List<Conversation>> list(int limit, int offset) async =>
      (await api.request(
        'GET',
        path,
        query: {'limit': '$limit', 'offset': '$offset'},
      ) as List).map((e) => Conversation.fromJson(jsonObject(e))).toList();
  Future<Conversation> find(String id) async =>
      Conversation.fromJson(jsonObject(await api.request('GET', '$path/$id')));
  Future<MessagePage> messages(
    String id, {
    String? before,
    String? after,
  }) async => MessagePage.fromJson(
    jsonObject(
      await api.request(
        'GET',
        '$path/$id/mensajes',
        query: {'limit': '30', 'antesDe': ?before, 'despuesDe': ?after},
      ),
    ),
  );
  Future<ChatMessage> send(String id, String messageId, String text) async =>
      ChatMessage.fromJson(
        jsonObject(
          await api.request(
            'POST',
            '$path/$id/mensajes',
            body: {'id': messageId, 'contenido': text},
          ),
        ),
      );
  Future<void> read(String id, String messageId) async {
    await api.request(
      'PATCH',
      '$path/$id/lectura',
      body: {'mensajeId': messageId},
    );
  }

  static String messageId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }
}
