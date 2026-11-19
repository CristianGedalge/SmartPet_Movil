import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../shared/services/api_client.dart';
import '../models/agent_message.dart';
import '../services/agent_chat_service.dart';
import '../services/agent_speech.dart';

class AgentChatScreen extends StatefulWidget {
  const AgentChatScreen({super.key, required this.service});

  final AgentChatGateway service;

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _speech = AgentSpeech();
  var _listening = false;
  var _dictationPrefix = '';
  final _messages = <AgentMessage>[
    const AgentMessage(
      role: AgentMessageRole.assistant,
      text: '¡Hola! Soy el Agente SmartPet. Puedo orientarte sobre mascotas, alertas, avistamientos y adopciones.',
      localOnly: true,
    ),
  ];
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _speech.stop();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_sending) return;
    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }
    _dictationPrefix = _controller.text.trim();
    setState(() => _error = null);
    try {
      final started = await _speech.start(
        onWords: (words) {
          if (!mounted) return;
          final text = dictationText(_dictationPrefix, words);
          setState(() {
            _controller.value = TextEditingValue(
              text: text,
              selection: TextSelection.collapsed(offset: text.length),
            );
          });
        },
        onError: (message) {
          if (!mounted) return;
          setState(() {
            _listening = false;
            _error = message;
          });
        },
        onDone: () {
          if (!mounted) return;
          setState(() => _listening = false);
        },
      );
      if (!mounted) return;
      setState(() {
        _listening = started;
        if (!started) {
          _error =
              'El reconocimiento de voz no está disponible en este dispositivo.';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _listening = false;
        _error = 'No se pudo usar el micrófono. Puedes escribir el mensaje.';
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_sending || text.isEmpty) return;
    if (_listening) {
      await _speech.stop();
      _listening = false;
    }
    final userMessage = AgentMessage(role: AgentMessageRole.user, text: text);
    setState(() {
      _sending = true;
      _error = null;
      _messages.add(userMessage);
      _controller.clear();
    });
    _moveToEnd();
    try {
      final answer = await widget.service.send(_messages);
      if (!mounted) return;
      setState(() {
        _messages.add(
          AgentMessage(role: AgentMessageRole.assistant, text: answer),
        );
      });
      _moveToEnd();
    } on ApiFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.remove(userMessage);
        _controller.text = text;
        _controller.selection = TextSelection.collapsed(offset: text.length);
        _error = error.message;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _moveToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Agente SmartPet'),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: AppColors.mint.withValues(alpha: .45),
            child: const Text(
              'El agente puede equivocarse. Verifica la información importante y consulta a un veterinario ante emergencias.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
          Expanded(
            child: ListView.separated(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_sending ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: _TypingBubble(),
                  );
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Material(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                  child: Row(
                    children: [
                      Expanded(child: Text(_error!)),
                      TextButton(
                        onPressed: _sending ? null : _send,
                        child: const Text('Volver a intentar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('agent-input'),
                    controller: _controller,
                    enabled: !_sending,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 1500,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _listening
                          ? 'Escuchando…'
                          : 'Escribe o dicta tu mensaje',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: _listening ? 'Detener dictado' : 'Dictar mensaje',
                  onPressed: _sending ? null : _toggleSpeech,
                  style: IconButton.styleFrom(
                    backgroundColor: _listening
                        ? const Color(0xFFB42318)
                        : AppColors.mint,
                    foregroundColor: _listening ? Colors.white : AppColors.ink,
                  ),
                  icon: Icon(
                    _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar mensaje',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.role == AgentMessageRole.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Semantics(
        label: mine ? 'Tu mensaje' : 'Respuesta del Agente SmartPet',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
            border: mine ? null : Border.all(color: AppColors.line),
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: mine ? Colors.white : AppColors.ink,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 10),
        Text('Pensando…'),
      ],
    ),
  );
}
