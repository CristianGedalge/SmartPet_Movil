import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartpet_movil/app.dart';
import 'package:smartpet_movil/config/api_config.dart';
import 'package:smartpet_movil/features/auth/services/session.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets(
    'inicio real, navegacion ciudadana y logout descartan rutas privadas',
    (tester) async {
      final store = MemoryTokenStore('saved');
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/profile')) {
            return http.Response(jsonEncode(profile()), 200);
          }
          if (request.url.path.endsWith('/mis-mascotas')) {
            return http.Response(jsonEncode([petJson()]), 200);
          }
          if (request.url.path.endsWith('/mascotas/pet-1')) {
            return http.Response(jsonEncode(petJson()), 200);
          }
          if (request.url.path.endsWith('/expire')) {
            return http.Response('{}', 401);
          }
          return http.Response('[]', 200);
        }),
      );
      final session = Session(api, store);
      await tester.pumpWidget(
        SmartPetApp(
          config: ApiConfig(
            apiUrl: api.baseUrl,
            mapStyleUrl: 'https://tiles.openfreemap.org/styles/liberty',
          ),
          session: session,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hola, Ana \u{1F44B}'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      await tester.tap(find.byType(NavigationDestination).at(3));
      await tester.pumpAndSettle();
      expect(find.text('Reportar avistamiento'), findsOneWidget);
      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();
      expect(find.text('Mis mascotas'), findsOneWidget);
      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();
      expect(find.text('Ficha de mascota'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Ficha de mascota'), findsNothing);
      expect(find.text('Mis mascotas'), findsOneWidget);
      await tester.tap(find.text('Luna'));
      await tester.pumpAndSettle();
      await expectLater(
        api.request('GET', '/expire'),
        throwsA(isA<ApiFailure>()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ficha de mascota'), findsNothing);
      expect(find.text('Iniciar sesi\u00f3n'), findsOneWidget);
      expect(store.value, isNull);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('sin token muestra ingreso y no solicita datos privados', (
    tester,
  ) async {
    var requests = 0;
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 500);
      }),
    );
    await tester.pumpWidget(
      SmartPetApp(
        config: ApiConfig(
          apiUrl: api.baseUrl,
          mapStyleUrl: 'https://tiles.openfreemap.org/styles/liberty',
        ),
        session: Session(api, MemoryTokenStore()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesi\u00f3n'), findsOneWidget);
    expect(requests, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
