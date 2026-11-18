import 'dart:async';

import 'package:flutter/material.dart';

import '../../../config/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/chat.dart';
import '../services/chat_connection.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.conversation,
    required this.service,
    this.connectionFactory,
  });
  final Conversation conversation;
  final ChatService service;
  final ChatConnection Function()? connectionFactory;
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _text = TextEditingController(), _scroll = ScrollController();
  late Conversation _chat = widget.conversation;
  late final ChatConnection _connection =
      widget.connectionFactory?.call() ??
      SocketChatConnection(widget.service.api);
  StreamSubscription<String?>? _subscription;
  List<ChatMessage> _messages = [];
  bool _initial = true,
      _fetching = false,
      _sending = false,
      _hasOlder = false,
      _active = true,
      _again = false;
  String? _error, _pendingId, _pendingText, _lastRead, _cursor;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connection.changes.listen((id) {
      if (!mounted || !_active) return;
      setState(() {});
      if (id == null || id == _chat.id) unawaited(_sync());
    });
    _connection.connect();
    unawaited(_sync());
    _scroll.addListener(_markVisible);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _connection.connect();
      unawaited(_sync());
    } else {
      _connection.disconnect();
    }
  }

  void _merge(List<ChatMessage> incoming) {
    final merged = {
      for (final message in _messages) message.id: message,
      for (final message in incoming) message.id: message,
    };
    _messages = merged.values.toList()
      ..sort((a, b) {
        final result = a.createdAt.compareTo(b.createdAt);
        return result == 0 ? a.id.compareTo(b.id) : result;
      });
  }

  Future<void> _sync() async {
    if (!_active || !mounted) return;
    if (_fetching) {
      _again = true;
      return;
    }
    _fetching = true;
    try {
      final chat = await widget.service.find(_chat.id);
      if (!mounted || !_active) return;
      final wasInitial = _cursor == null;
      var page = await widget.service.messages(_chat.id, after: _cursor);
      if (!mounted || !_active) return;
      setState(() {
        _chat = chat;
        if (wasInitial) _hasOlder = page.hasMore;
        _merge(page.items);
        if (page.items.isNotEmpty) _cursor = page.items.last.id;
        _initial = false;
        _error = null;
      });
      // Recover every missed page after reconnect rather than just the last 30 messages.
      while (!wasInitial && page.hasMore && page.items.isNotEmpty) {
        page = await widget.service.messages(
          _chat.id,
          after: page.items.last.id,
        );
        if (!mounted || !_active) return;
        setState(() {
          _merge(page.items);
          if (page.items.isNotEmpty) _cursor = page.items.last.id;
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _markVisible());
    } catch (error) {
      if (mounted && _active) setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _fetching = false);
      } else {
        _fetching = false;
      }
      if (_again && mounted && _active) {
        _again = false;
        unawaited(_sync());
      }
    }
  }

  void _markVisible() {
    if (!mounted ||
        !_active ||
        _messages.isEmpty ||
        !_scroll.hasClients ||
        _scroll.offset > 60) {
      return;
    }
    final messageId = _cursor;
    if (messageId == null) return;
    if (_lastRead == messageId) return;
    _lastRead = messageId;
    unawaited(
      widget.service.read(_chat.id, messageId).catchError((Object error) {
        if (mounted && _lastRead == messageId) {
          _lastRead = null;
          setState(() => _error = error.toString());
        }
      }),
    );
  }

  Future<void> _older() async {
    if (_fetching || _messages.isEmpty) return;
    setState(() => _fetching = true);
    try {
      final page = await widget.service.messages(
        _chat.id,
        before: _messages.first.id,
      );
      if (mounted && _active) {
        setState(() {
          _merge(page.items);
          _hasOlder = page.hasMore;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _fetching = false);
      if (_again) {
        _again = false;
        unawaited(_sync());
      }
    }
  }

  Future<void> _send() async {
    final value = _text.text.trim();
    if (_sending || value.isEmpty) return;
    if (value.length > 4000) {
      setState(() => _error = 'Usa como máximo 4000 caracteres.');
      return;
    }
    if (_pendingText != value) {
      _pendingId = ChatService.messageId();
      _pendingText = value;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final message = await widget.service.send(_chat.id, _pendingId!, value);
      if (!mounted) return;
      setState(() {
        _merge([message]);
        if (_text.text.trim() == value) _text.clear();
        _pendingId = null;
        _pendingText = null;
      });
      if (_scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        );
      }
      unawaited(_sync());
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _connection.dispose();
    _text.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _chat.name,
            style: const TextStyle(fontSize: 18),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _chat.contextLabel,
            style: const TextStyle(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Actualizar mensajes',
          onPressed: () {
            _connection.connect();
            unawaited(_sync());
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Column(
        children: [
          if (!_connection.connected)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Reconectando al chat… Puedes actualizar o volver a intentarlo.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: InlineMessage(_error!),
            ),
          Expanded(
            child: _initial
                ? (_error == null
                      ? const LoadingPanel()
                      : Center(
                          child: OutlinedButton(
                            onPressed: _sync,
                            child: const Text('Volver a intentar'),
                          ),
                        ))
                : _messages.isEmpty
                ? const Center(
                    child: Text('Inicia la conversación con un mensaje.'),
                  )
                : ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_hasOlder ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return TextButton(
                          onPressed: _fetching ? null : _older,
                          child: Text(
                            _fetching ? 'Cargando…' : 'Cargar anteriores',
                          ),
                        );
                      }
                      final message = _messages[_messages.length - 1 - index];
                      return Align(
                        alignment: message.mine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .82,
                          ),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: message.mine ? AppColors.mint : Colors.white,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message.text),
                              const SizedBox(height: 6),
                              Text(
                                '${message.mine ? 'Tú' : 'Recibido'} · ${friendlyDate(context, message.createdAt)}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    maxLength: 4000,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje',
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'Enviar mensaje',
                  onPressed: _sending || _initial ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
