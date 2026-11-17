import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/alertas/models/lost_alert.dart';
import 'package:smartpet_movil/features/alertas/screens/alert_form_screen.dart';
import 'package:smartpet_movil/features/alertas/services/alerts_service.dart';
import 'package:smartpet_movil/features/mascotas/services/pets_service.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

import 'support/fixtures.dart';

void main() {
  testWidgets(
    'editar alerta guarda punto interno y UTC sin modificar mascota ni estado',
    (tester) async {
      Map<String, dynamic>? submitted;
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          expect(request.method, 'PATCH');
          expect(request.url.path, endsWith('/alertas-extravio/alert-1'));
          submitted = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        }),
      )..token = 'jwt';
      final alert = LostAlert.fromJson({
        'id': 'alert-1',
        'mascotaId': 'pet-1',
        'mascota': petJson(),
        'estado': 'ACTIVA',
        'fechaExtravio': '2025-01-01T13:00:00Z',
        'latitud': -16.5,
        'longitud': -68.15,
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: AlertFormScreen(
            service: AlertsService(api),
            pets: PetsService(api),
            styleUrl: 'https://tiles.openfreemap.org/styles/liberty',
            alert: alert,
            mapBuilder: (point, onChanged) => TextButton(
              onPressed: () =>
                  onChanged(const LatLng(-16.512345678, -68.123456789)),
              child: Text(
                point == null ? 'Seleccionar punto' : 'Cambiar punto',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('-16.5'), findsNothing);
      expect(find.text('-68.15'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), ' Cerca del parque ');
      final mapButton = find.text('Cambiar punto');
      await tester.ensureVisible(mapButton);
      await tester.tap(mapButton);
      await tester.pump();
      final save = find.text('Guardar cambios');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(submitted, {
        'descripcion': 'Cerca del parque',
        'fechaExtravio': '2025-01-01T13:00:00.000Z',
        'latitud': -16.51234568,
        'longitud': -68.12345679,
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      api.close();
    },
  );

  testWidgets(
    'crear alerta no confirma el centro inicial ni envía un formulario incompleto',
    (tester) async {
      var requests = 0;
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((_) async {
          requests++;
          return http.Response('{}', 201);
        }),
      )..token = 'jwt';
      await tester.pumpWidget(
        MaterialApp(
          home: AlertFormScreen(
            service: AlertsService(api),
            pets: PetsService(api),
            styleUrl: 'https://tiles.openfreemap.org/styles/liberty',
            mapBuilder: (point, _) {
              expect(point, isNull);
              return const Text('Mapa sin selección');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(FilledButton, 'Publicar alerta');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(find.text('Selecciona tu mascota.'), findsOneWidget);
      expect(requests, 0);
      await tester.pumpWidget(const SizedBox());
      api.close();
    },
  );
}
