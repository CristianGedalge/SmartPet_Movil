import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/agente/models/agent_message.dart';
import 'package:smartpet_movil/features/agente/screens/agent_chat_screen.dart';
import 'package:smartpet_movil/features/agente/services/agent_chat_service.dart';
import 'package:smartpet_movil/features/agente/services/agent_speech.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

class FakeAgent implements AgentChatGateway {
  var attempts = 0;
  List<AgentMessage>? received;

  @override
  Future<String> send(List<AgentMessage> messages) async {
    attempts++;
    received = List.of(messages);
    if (attempts == 1) throw const ApiFailure('Error temporal.');
    return 'Puedes crearla desde la sección Alertas.';
  }
}

void main() {
  test('une el texto escrito con lo dictado', () {
    expect(dictationText('Hola', 'cómo creo una alerta'), 'Hola cómo creo una alerta');
    expect(dictationText('', '  alerta  '), 'alerta');
    expect(dictationText('a' * 1500, 'más'), 'a' * 1500);
  });

  test('envía historial autenticado al endpoint del agente', () async {
    final api = ApiClient(
      'https://example.test/api/v1',
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/agente/chat');
        expect(request.headers['authorization'], 'Bearer citizen-token');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['mensajes'], [
          {'rol': 'USUARIO', 'contenido': '¿Cómo creo una alerta?'},
        ]);
        return http.Response(jsonEncode({'respuesta': 'Abre Alertas.'}), 201);
      }),
    )..token = 'citizen-token';
    addTearDown(api.close);
    final answer = await AgentChatService(api).send(const [
      AgentMessage(
        role: AgentMessageRole.assistant,
        text: 'Bienvenida local',
        localOnly: true,
      ),
      AgentMessage(role: AgentMessageRole.user, text: '¿Cómo creo una alerta?'),
    ]);
    expect(answer, 'Abre Alertas.');
  });

  testWidgets('conserva el texto ante error y permite reintentar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fake = FakeAgent();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: AgentChatScreen(service: fake),
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey('agent-input')),
      '¿Cómo creo una alerta?',
    );
    await tester.tap(find.byTooltip('Enviar mensaje'));
    await tester.pumpAndSettle();
    expect(find.text('Error temporal.'), findsOneWidget);
    expect(find.text('¿Cómo creo una alerta?'), findsOneWidget);
    await tester.tap(find.text('Volver a intentar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Puedes crearla desde la sección Alertas.'),
      findsOneWidget,
    );
    expect(fake.attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
