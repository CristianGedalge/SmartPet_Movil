import '../../../shared/models/json_values.dart';

class ChatMessage {
  ChatMessage.fromJson(JsonObject json)
    : id = requiredString(json, 'id'),
      text = requiredString(json, 'contenido'),
      createdAt = DateTime.parse(requiredString(json, 'createdAt')),
      mine = json['esPropio'] == true;
  final String id, text;
  final DateTime createdAt;
  final bool mine;
}

class Conversation {
  Conversation.fromJson(JsonObject json)
    : id = requiredString(json, 'id'),
      name = requiredString(jsonObject(json['interlocutor']), 'nombre'),
      title = requiredString(jsonObject(json['contexto']), 'titulo'),
      type = requiredString(jsonObject(json['contexto']), 'tipo'),
      unread = integerValue(json['noLeidos']) ?? 0,
      last = json['ultimoMensaje'] == null
          ? null
          : ChatMessage.fromJson(jsonObject(json['ultimoMensaje']));
  final String id, name, title, type;
  final int unread;
  final ChatMessage? last;
  String get contextLabel =>
      '${type == 'ALERTA' ? 'Alerta' : 'Avistamiento'} · $title';
}

class MessagePage {
  MessagePage.fromJson(JsonObject json)
    : items = (json['items'] as List)
          .map((e) => ChatMessage.fromJson(jsonObject(e)))
          .toList(),
      hasMore = json['hayMas'] == true;
  final List<ChatMessage> items;
  final bool hasMore;
}
