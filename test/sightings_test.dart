import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:smartpet_movil/features/avistamientos/models/sighting.dart';
import 'package:smartpet_movil/features/avistamientos/screens/sighting_detail_screen.dart';
import 'package:smartpet_movil/features/avistamientos/screens/sighting_form_screen.dart';
import 'package:smartpet_movil/features/avistamientos/services/sightings_service.dart';
import 'package:smartpet_movil/features/mascotas/services/pets_service.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

Map<String, dynamic> sightingJson({
  bool mine = true,
  String status = 'ACTIVO',
}) => {
  'id': 'sighting-1',
  'especieId': 1,
  'especie': {'id': 1, 'nombre': 'Perro'},
  'descripcion': 'Con collar rojo',
  'direccion': 'Plaza central',
  'fechaAvistamiento': '2020-01-01T16:00:00Z',
  'latitud': -17.7833,
  'longitud': -63.1821,
  'estado': status,
  'esPropio': mine,
  'fotos': [],
};

Widget app(Widget child) => MaterialApp(
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: child,
);

void main() {
  test(
    'cliente usa multipart, sesión, paginación y acciones del contrato',
    () async {
      final calls = <http.Request>[];
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((r) async {
          calls.add(r);
          if (r.method == 'GET') {
            return http.Response('[]', 200);
          }
          return http.Response(jsonEncode(sightingJson()), 200);
        }),
      )..token = 'jwt';
      final service = SightingsService(api);
      await service.list(10, 20, mine: false);
      expect(calls.last.headers.containsKey('Authorization'), false);
      expect(calls.last.url.queryParameters['offset'], '20');
      await service.list(10, 0, mine: true);
      expect(calls.last.url.path, endsWith('/avistamientos/mis-avistamientos'));
      expect(calls.last.headers['Authorization'], 'Bearer jwt');
      await service.create(
        {
          'especieId': 1,
          'descripcion': 'Perro',
          'direccion': 'Plaza',
          'latitud': -17.78,
          'longitud': -63.18,
          'fechaAvistamiento': '2020-01-01T16:00:00Z',
        },
        [
          const UploadPhoto([137, 80, 78, 71], 'image/png', 'photo.png'),
        ],
      );
      expect(
        calls.last.headers['content-type'],
        startsWith('multipart/form-data'),
      );
      final multipart = latin1.decode(calls.last.bodyBytes);
      expect(multipart, contains('name="fotos"; filename="photo.png"'));
      expect(multipart, contains('name="latitud"'));
      expect(multipart, isNot(contains('usuarioId')));
      expect(multipart, isNot(contains('alertaId')));
      await service.close('sighting-1', cancel: true);
      expect(calls.last.method, 'PATCH');
      expect(calls.last.url.path, endsWith('/sighting-1/cancelar'));
      expect(calls.last.body, '{}');
      api.close();
    },
  );

  testWidgets('publicación exige datos, punto y foto antes de enviar', (
    tester,
  ) async {
    var posts = 0;
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((r) async {
        if (r.method == 'POST') posts++;
        return http.Response('[{"id":1,"nombre":"Perro"}]', 200);
      }),
    )..token = 'jwt';
    await tester.pumpWidget(
      app(
        SightingFormScreen(
          service: SightingsService(api),
          styleUrl: 'https://example.com/style',
          mapBuilder: (_, change) => TextButton(
            onPressed: () => change(const LatLng(-17.78, -63.18)),
            child: const Text('Marcar punto'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final save = find.text('Publicar avistamiento');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(posts, 0);
    await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perro').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Con collar rojo');
    await tester.enterText(find.byType(TextFormField).at(1), 'Plaza');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(
      find.text('Marca dónde viste a la mascota en el mapa.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Marcar punto'));
    await tester.tap(find.text('Marcar punto'));
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Agrega al menos una foto.'), findsOneWidget);
    expect(posts, 0);
    await tester.pumpWidget(const SizedBox());
    api.close();
  });

  testWidgets('publica con foto y punto sin pedir mascota o alerta', (
    tester,
  ) async {
    http.Request? submitted;
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((r) async {
        if (r.method == 'GET') {
          return http.Response('[{"id":1,"nombre":"Perro"}]', 200);
        }
        submitted = r;
        return http.Response(jsonEncode(sightingJson()), 201);
      }),
    )..token = 'jwt';
    await tester.pumpWidget(
      app(
        SightingFormScreen(
          service: SightingsService(api),
          styleUrl: 'https://example.com/style',
          mapBuilder: (_, change) => TextButton(
            onPressed: () => change(const LatLng(-17.78, -63.18)),
            child: const Text('Marcar punto'),
          ),
          photoPicker: (_, available) async => [
            UploadPhoto(
              base64Decode(
                'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1cAAAAASUVORK5CYII=',
              ),
              'image/png',
              'photo.png',
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Perro').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Con collar rojo');
    await tester.enterText(find.byType(TextFormField).at(1), 'Plaza central');
    await tester.ensureVisible(find.text('Marcar punto'));
    await tester.tap(find.text('Marcar punto'));
    await tester.ensureVisible(find.text('Agregar fotos'));
    await tester.tap(find.text('Agregar fotos'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Publicar avistamiento'));
    await tester.tap(find.text('Publicar avistamiento'));
    await tester.pumpAndSettle();
    expect(submitted?.method, 'POST');
    final multipart = latin1.decode(submitted!.bodyBytes);
    expect(multipart, contains('name="fotos"'));
    expect(multipart, contains('name="fechaAvistamiento"'));
    expect(multipart, isNot(contains('mascotaId')));
    expect(multipart, isNot(contains('alertaId')));
    await tester.pumpWidget(const SizedBox());
    api.close();
  });

  testWidgets('edición envía JSON con UTC y punto interno sin metadatos', (
    tester,
  ) async {
    Map<String, dynamic>? submitted;
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((r) async {
        if (r.method == 'GET') {
          return http.Response('[{"id":1,"nombre":"Perro"}]', 200);
        }
        submitted = jsonDecode(r.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(sightingJson()), 200);
      }),
    )..token = 'jwt';
    await tester.pumpWidget(
      app(
        SightingFormScreen(
          service: SightingsService(api),
          styleUrl: 'https://example.com/style',
          sighting: Sighting.fromJson(sightingJson()),
          mapBuilder: (_, change) => TextButton(
            onPressed: () => change(const LatLng(0, -63.123456789)),
            child: const Text('Marcar punto'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Marcar punto'));
    await tester.tap(find.text('Marcar punto'));
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(submitted?['latitud'], 0);
    expect(submitted?['longitud'], -63.12345679);
    expect(submitted?['fechaAvistamiento'], '2020-01-01T16:00:00.000Z');
    expect(submitted?.keys, isNot(contains('estado')));
    expect(submitted?.keys, isNot(contains('usuarioId')));
    expect(submitted?.keys, isNot(contains('fotos')));
    await tester.pumpWidget(const SizedBox());
    api.close();
  });

  for (final entry in [
    (true, 'ACTIVO'),
    (false, 'ACTIVO'),
    (true, 'CERRADO'),
  ]) {
    testWidgets('acciones propias según servidor: $entry', (tester) async {
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode(sightingJson(mine: entry.$1, status: entry.$2)),
            200,
          ),
        ),
      )..token = 'jwt';
      await tester.pumpWidget(
        app(
          SightingDetailScreen(
            service: SightingsService(api),
            id: 'sighting-1',
            styleUrl: 'https://example.com/style',
            mapBuilder: (_) => const Text('Mapa'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final editable = entry.$1 && entry.$2 == 'ACTIVO';
      expect(
        find.text('Editar datos'),
        editable ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Cerrar avistamiento'),
        editable ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Agregar fotografías'),
        editable ? findsOneWidget : findsNothing,
      );
      expect(find.textContaining('-17.7833'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      api.close();
    });
  }
}
