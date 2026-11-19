import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/suscripcion/models/plan_offer.dart';
import 'package:smartpet_movil/features/suscripcion/screens/payment_screen.dart';
import 'package:smartpet_movil/features/suscripcion/services/subscription_service.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

void main() {
  const plan = PlanOffer(
    id: '7c069260-c896-4c95-a09b-cb4ff6cb8337',
    nombre: 'Plus',
    precio: 29,
    descripcion: 'Más oportunidades para encontrar a tu mascota.',
    busquedasFotoMes: 40,
    mensajesAgenteMes: 200,
  );

  test(
    'servicio envía la tarjeta normalizada y recibe la simulación',
    () async {
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          expect(request.url.path, '/api/v1/pagos');
          expect(jsonDecode(request.body), {
            'planId': plan.id,
            'titular': 'Ana Perez',
            'numeroTarjeta': '4242424242424242',
            'mesExpiracion': 12,
            'anioExpiracion': 2030,
            'cvv': '123',
          });
          return http.Response(
            jsonEncode({
              'modoPrueba': true,
              'pago': {'ultimosCuatro': '4242'},
            }),
            201,
          );
        }),
      )..token = 'jwt';

      final result = await SubscriptionService(api).simulatePayment(
        plan: plan,
        holder: ' Ana Perez ',
        cardNumber: '4242 4242 4242 4242',
        expiryMonth: 12,
        expiryYear: 2030,
        cvv: '123',
      );
      expect(result['modoPrueba'], true);
      api.close();
    },
  );

  testWidgets('formulario carga únicamente la tarjeta aprobada de prueba', (
    tester,
  ) async {
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((_) async => http.Response('{}', 200)),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: PaymentScreen(
          plan: plan,
          service: SubscriptionService(api),
          defaultHolder: 'Ana Perez',
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('use-test-card')));
    await tester.pump();

    expect(find.text('4242 4242 4242 4242'), findsWidgets);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('card-cvv')))
          .controller
          ?.text,
      '123',
    );
    expect(find.textContaining('no se cobrará dinero real'), findsOneWidget);
    api.close();
  });
}
