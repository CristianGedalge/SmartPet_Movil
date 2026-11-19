import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../shared/services/api_client.dart';

abstract interface class ChatConnection {
  bool get connected;
  Stream<String?> get changes;
  void connect();
  void disconnect();
  void dispose();
}

class SocketChatConnection implements ChatConnection {
  SocketChatConnection(this.api);
  final ApiClient api;
  final _changes = StreamController<String?>.broadcast();
  io.Socket? _socket;
  bool _disposed = false;
  @override
  bool get connected => _socket?.connected == true;
  @override
  Stream<String?> get changes => _changes.stream;
  @override
  void connect() {
    if (_disposed || api.token == null) return;
    _socket?.dispose();
    final origin = Uri.parse(api.baseUrl)
        .replace(path: '/chat', query: null, fragment: null)
        .toString();
    final socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': api.token})
          .enableForceNew()
          .disableMultiplex()
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;
    socket.onConnect((_) {
      if (!_disposed) _changes.add(null);
    });
    socket.onDisconnect((_) {
      if (!_disposed) _changes.add('');
    });
    socket.onConnectError((_) {
      if (!_disposed) _changes.add('');
    });
    socket.on('chat:actualizado', (data) {
      if (!_disposed && data is Map && data['conversacionId'] is String) {
        _changes.add(data['conversacionId'] as String);
      }
    });
    socket.connect();
  }

  @override
  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disconnect();
    unawaited(_changes.close());
  }
}
