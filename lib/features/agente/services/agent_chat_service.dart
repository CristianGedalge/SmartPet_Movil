import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/agent_message.dart';

abstract interface class AgentChatGateway {
  Future<String> send(List<AgentMessage> messages);
}

class AgentChatService implements AgentChatGateway {
  AgentChatService(this.api);

  final ApiClient api;

  @override
  Future<String> send(List<AgentMessage> messages) async {
    final history = messages.where((message) => !message.localOnly).toList();
    if (history.isEmpty || history.last.role != AgentMessageRole.user) {
      throw const ApiFailure('Escribe un mensaje para continuar.');
    }
    final limited = history.length > 11
        ? history.sublist(history.length - 11)
        : history;
    final data = jsonObject(
      await api.request(
        'POST',
        '/agente/chat',
        body: {'mensajes': limited.map((message) => message.toJson()).toList()},
      ),
    );
    final answer = data['respuesta'];
    if (answer is! String || answer.trim().isEmpty) {
      throw const ApiFailure(
        'No pudimos obtener una respuesta. Intenta nuevamente.',
      );
    }
    return answer.trim();
  }
}
