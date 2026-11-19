import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/chat/models/chat.dart';
import 'package:smartpet_movil/features/chat/services/chat_connection.dart';
import 'package:smartpet_movil/features/chat/services/chat_service.dart';
import 'package:smartpet_movil/features/chat/screens/chat_screen.dart';
import 'package:smartpet_movil/features/chat/screens/chat_inbox_screen.dart';
import 'package:smartpet_movil/features/chat/widgets/contact_author_button.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

Map<String, dynamic> conversationJson() => {
  'id': 'chat-1',
  'contexto': {
    'id': 'post-1',
    'tipo': 'ALERTA',
    'titulo': 'Luna',
    'estado': 'ACTIVA',
  },
  'interlocutor': {'nombre': 'Ana Perez'},
  'ultimoMensaje': null,
  'noLeidos': 2,
};
Map<String, dynamic> messageJson(String id, int second, {bool mine = false}) =>
    {
      'id': id,
      'contenido': 'Mensaje $id',
      'createdAt': '2026-11-18T12:00:${second.toString().padLeft(2, '0')}.000Z',
      'esPropio': mine,
    };
http.Response response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

class FakeChatConnection implements ChatConnection {
  final events = StreamController<String?>.broadcast();
  int connections = 0, disconnections = 0;
  bool disposed = false;
  @override
  bool connected = false;
  @override
  Stream<String?> get changes => events.stream;
  @override
  void connect() {
    connections++;
    connected = true;
  }

  @override
  void disconnect() {
    disconnections++;
    connected = false;
  }

  void notify([String? id]) {
    if (!disposed) events.add(id);
  }

  @override
  void dispose() {
    disposed = true;
    connected = false;
    unawaited(events.close());
  }
}

void main() {
  test(
    'servicio usa JWT, contexto sin destinatario y UUIDv4 distinto por envío',
    () async {
      final requests = <http.Request>[];
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          requests.add(request);
          expect(request.headers['authorization'], 'Bearer saved');
          if (request.url.path.endsWith('/mensajes')) {
            return response({
              'items': [messageJson('m1', 1)],
              'hayMas': true,
            });
          }
          return response(conversationJson());
        }),
      )..token = 'saved';
      addTearDown(api.close);
      final service = ChatService(api);
      await service.open(alertId: 'post-1');
      expect(jsonDecode(requests.first.body), {'alertaId': 'post-1'});
      final page = await service.messages('chat-1', after: 'm0');
      expect(page.hasMore, true);
      expect(page.items.single.text, 'Mensaje m1');
      expect(requests.last.url.queryParameters, {
        'limit': '30',
        'despuesDe': 'm0',
      });
      final ids = List.generate(100, (_) => ChatService.messageId());
      expect(ids.toSet().length, 100);
      expect(
        ids.every(
          (id) => RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ).hasMatch(id),
        ),
        true,
      );
    },
  );
  testWidgets('bandeja muestra pendientes y libera conexión al salir', (
    tester,
  ) async {
    final live = FakeChatConnection();
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((_) async => response([conversationJson()])),
    )..token = 'saved';
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: ChatInboxScreen(
          service: ChatService(api),
          connectionFactory: () => live,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ana Perez'), findsOneWidget);
    expect(find.text('2 sin leer'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(live.disposed, true);
  });
  testWidgets(
    'carga anteriores y reintenta envío con mismo ID sin perder borrador',
    (tester) async {
      final live = FakeChatConnection();
      final sent = <Map<String, dynamic>>[];
      final reads = <String>[];
      var oldCalls = 0;
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/lectura')) {
            reads.add((jsonDecode(request.body) as Map)['mensajeId'] as String);
            return response({'leido': true});
          }
          if (request.url.path.endsWith('/mensajes')) {
            if (request.method == 'POST') {
              final body = jsonDecode(request.body) as Map<String, dynamic>;
              sent.add(body);
              if (sent.length == 1) {
                return response({'message': 'Error temporal de prueba'}, 503);
              }
              return response({
                'id': body['id'],
                'contenido': body['contenido'],
                'createdAt': '2026-11-18T12:00:03Z',
                'esPropio': true,
              }, 201);
            }
            if (request.url.queryParameters.containsKey('antesDe')) {
              oldCalls++;
              return response({
                'items': [messageJson('m0', 0)],
                'hayMas': false,
              });
            }
            if (request.url.queryParameters.containsKey('despuesDe')) {
              return response({'items': [], 'hayMas': false});
            }
            return response({
              'items': [messageJson('m1', 1), messageJson('m2', 2)],
              'hayMas': true,
            });
          }
          return response(conversationJson());
        }),
      )..token = 'saved';
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ChatScreen(
            conversation: Conversation.fromJson(conversationJson()),
            service: ChatService(api),
            connectionFactory: () => live,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(reads, contains('m2'));
      await tester.tap(find.text('Cargar anteriores'));
      await tester.pumpAndSettle();
      expect(oldCalls, 1);
      await tester.enterText(find.byType(TextField), 'Lo vi en la plaza');
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(find.text('Lo vi en la plaza'), findsOneWidget);
      expect(sent.length, 1);
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(sent.length, 2);
      expect(sent.first['id'], sent.last['id']);
      expect(
        (tester.widget<TextField>(find.byType(TextField))).controller!.text,
        isEmpty,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      expect(live.disposed, true);
    },
  );
  testWidgets(
    'reconexión recupera todas las páginas sin duplicar y pausa al salir de app',
    (tester) async {
      final live = FakeChatConnection();
      var recovering = false;
      final cursors = <String>[];
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/lectura')) {
            return response({'leido': true});
          }
          if (request.url.path.endsWith('/mensajes')) {
            final after = request.url.queryParameters['despuesDe'];
            if (after != null) cursors.add(after);
            if (recovering && after == 'm1') {
              return response({
                'items': [messageJson('m2', 2)],
                'hayMas': true,
              });
            }
            if (recovering && after == 'm2') {
              return response({
                'items': [messageJson('m3', 3)],
                'hayMas': false,
              });
            }
            return response({
              'items': after == null ? [messageJson('m1', 1)] : [],
              'hayMas': false,
            });
          }
          return response(conversationJson());
        }),
      )..token = 'saved';
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ChatScreen(
            conversation: Conversation.fromJson(conversationJson()),
            service: ChatService(api),
            connectionFactory: () => live,
          ),
        ),
      );
      await tester.pumpAndSettle();
      recovering = true;
      live.notify();
      await tester.pumpAndSettle();
      expect(cursors, containsAllInOrder(['m1', 'm2']));
      expect(find.text('Mensaje m3'), findsOneWidget);
      live.notify('chat-1');
      await tester.pumpAndSettle();
      expect(find.text('Mensaje m3'), findsOneWidget);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      expect(live.disconnections, greaterThan(0));
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(live.connections, greaterThan(1));
      await tester.pumpWidget(const SizedBox());
      expect(live.disposed, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'enviar no salta mensajes recibidos antes de la respuesta del envío',
    (tester) async {
      final live = FakeChatConnection();
      var sent = false;
      final cursors = <String>[];
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/lectura')) {
            return response({'leido': true});
          }
          if (request.url.path.endsWith('/mensajes')) {
            if (request.method == 'POST') {
              sent = true;
              return response({
                ...messageJson('m3', 3, mine: true),
                'contenido': 'Respuesta propia',
              }, 201);
            }
            final after = request.url.queryParameters['despuesDe'];
            if (after != null) {
              cursors.add(after);
            }
            return response({
              'items': sent && after == 'm1'
                  ? [
                      messageJson('m2', 2),
                      {
                        ...messageJson('m3', 3, mine: true),
                        'contenido': 'Respuesta propia',
                      },
                    ]
                  : after == null
                  ? [messageJson('m1', 1)]
                  : [],
              'hayMas': false,
            });
          }
          return response(conversationJson());
        }),
      )..token = 'saved';
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: ChatScreen(
            conversation: Conversation.fromJson(conversationJson()),
            service: ChatService(api),
            connectionFactory: () => live,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Respuesta propia');
      await tester.tap(find.byTooltip('Enviar mensaje'));
      await tester.pumpAndSettle();
      expect(cursors, contains('m1'));
      expect(find.text('Mensaje m2'), findsOneWidget);
      expect(find.text('Respuesta propia'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('contactar autor bloquea doble apertura y explica autochat', (
    tester,
  ) async {
    final pending = Completer<http.Response>();
    var calls = 0;
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((request) {
        calls++;
        expect(jsonDecode(request.body), {'avistamientoId': 'post-1'});
        return pending.future;
      }),
    )..token = 'saved';
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: ContactAuthorButton(
            service: ChatService(api),
            sightingId: 'post-1',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Contactar al autor'));
    await tester.pump();
    expect(find.text('Abriendo chat…'), findsOneWidget);
    expect(calls, 1);
    pending.complete(response({'message': 'Esta publicación es tuya.'}, 409));
    await tester.pumpAndSettle();
    expect(find.text('Esta publicación es tuya.'), findsOneWidget);
    expect(find.text('Contactar al autor'), findsOneWidget);
  });
}
