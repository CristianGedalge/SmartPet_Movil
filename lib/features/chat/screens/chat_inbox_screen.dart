import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/controllers/paged_list_controller.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../../shared/widgets/paged_list_view.dart';
import '../models/chat.dart';
import '../services/chat_service.dart';
import '../services/chat_connection.dart';
import 'chat_screen.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({
    super.key,
    required this.service,
    this.connectionFactory,
  });
  final ChatService service;
  final ChatConnection Function()? connectionFactory;
  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen>
    with WidgetsBindingObserver {
  late final _list = PagedListController<Conversation>(
    fetchPage: widget.service.list,
  );
  late final ChatConnection _connection =
      widget.connectionFactory?.call() ??
      SocketChatConnection(widget.service.api);
  StreamSubscription<String?>? _subscription;
  Timer? _debounce;
  bool _visible = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _list.refresh();
    _subscription = _connection.changes.listen((id) {
      if (!mounted || !_visible) return;
      setState(() {});
      if (id != '') {
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 200), () {
          if (mounted && _visible) unawaited(_list.refresh());
        });
      }
    });
    _connection.connect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _visible) {
      _connection.connect();
      _list.refresh();
    } else {
      _connection.disconnect();
      _debounce?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    unawaited(_subscription?.cancel());
    _connection.dispose();
    _list.dispose();
    super.dispose();
  }

  Future<void> _open(Conversation chat) async {
    _visible = false;
    _debounce?.cancel();
    _connection.disconnect();
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversation: chat,
          service: widget.service,
          connectionFactory: widget.connectionFactory,
        ),
      ),
    );
    if (mounted) {
      _visible = true;
      _connection.connect();
      await _list.refresh();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mensajes'),
      actions: [
        IconButton(
          tooltip: 'Actualizar conversaciones',
          onPressed: () {
            _connection.connect();
            _list.refresh();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: PagedListView<Conversation>(
      controller: _list,
      header: Text(
        _connection.connected
            ? 'Tus conversaciones privadas'
            : 'Conectando al chat… Puedes deslizar para actualizar.',
      ),
      empty: const EmptyPanel(
        title: 'Todavía no tienes conversaciones',
        message:
            'Abre una alerta o un avistamiento y pulsa Contactar al autor.',
        icon: Icons.chat_bubble_outline_rounded,
      ),
      itemBuilder: (context, chat) => AppCard(
        onTap: () => _open(chat),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    chat.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (chat.unread > 0)
                  Chip(label: Text('${chat.unread} sin leer')),
              ],
            ),
            Text(chat.contextLabel),
            const SizedBox(height: 8),
            Text(
              chat.last == null
                  ? 'Aún no hay mensajes'
                  : '${chat.last!.mine ? 'Tú: ' : ''}${chat.last!.text}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (chat.last != null)
              Text(
                friendlyDate(context, chat.last!.createdAt),
                style: const TextStyle(fontSize: 11),
              ),
          ],
        ),
      ),
    ),
  );
}
