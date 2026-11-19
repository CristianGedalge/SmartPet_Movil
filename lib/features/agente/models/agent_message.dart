enum AgentMessageRole { user, assistant }

class AgentMessage {
  const AgentMessage({
    required this.role,
    required this.text,
    this.localOnly = false,
  });

  final AgentMessageRole role;
  final String text;
  final bool localOnly;

  Map<String, dynamic> toJson() => {
    'rol': role == AgentMessageRole.user ? 'USUARIO' : 'ASISTENTE',
    'contenido': text,
  };
}
