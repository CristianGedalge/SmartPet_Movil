import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/adopciones/models/adoption.dart';
import 'package:smartpet_movil/features/adopciones/screens/adoptions_screen.dart';
import 'package:smartpet_movil/features/adopciones/screens/adoption_detail_screen.dart';
import 'package:smartpet_movil/features/adopciones/services/adoptions_service.dart';
import 'package:smartpet_movil/shared/controllers/paged_list_controller.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

import 'support/fixtures.dart';

Map<String, dynamic> adoptionJson([String id = 'publication-1']) => {
  'id': id,
  'descripcion': 'Busca una familia responsable.',
  'requisitos': 'Visita al refugio.',
  'estado': 'PUBLICADA',
  'mascota': {...petJson(), 'pesoKg': '12.50', 'edadAproximadaMeses': 18},
  'establecimiento': {
    'id': 'place-1',
    'nombre': 'Refugio Esperanza',
    'tipo': 'REFUGIO',
    'direccion': 'Calle Central 123',
    'telefono': '70000000',
    'horarioAtencion': '9:00 a 18:00',
  },
};

void main() {
  test(
    'interpreta contrato público y no incorpora registro privado inesperado',
    () {
      final item = AdoptionPublication.fromJson({
        ...adoptionJson(),
        'registroAdopcion': {'nombreAdoptante': 'Dato privado'},
      });
      expect(item.pet.pesoKg, 12.5);
      expect(item.pet.edadMeses, 18);
      expect(item.establishment.typeLabel, 'Refugio');
      expect(item.pet.photos, isEmpty);
    },
  );
  test('consulta catálogo y detalle sin JWT y conserva limit/offset', () async {
    final paths = <String>[];
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.headers.containsKey('authorization'), false);
        paths.add(request.url.path);
        if (request.url.path.endsWith('/adopciones')) {
          expect(request.url.queryParameters, {'limit': '10', 'offset': '20'});
          return http.Response(jsonEncode([adoptionJson()]), 200);
        }
        return http.Response(jsonEncode(adoptionJson()), 200);
      }),
    )..token = 'private-session-token';
    addTearDown(api.close);
    final service = AdoptionsService(api);
    expect((await service.list(10, 20)).single.pet.nombre, 'Luna');
    expect((await service.find('publication-1')).id, 'publication-1');
    expect(paths, ['/api/v1/adopciones', '/api/v1/adopciones/publication-1']);
  });
  test(
    'respuestas inválidas y publicación retirada producen errores legibles',
    () async {
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient(
          (request) async => request.url.path.endsWith('/adopciones')
              ? http.Response('{}', 200)
              : http.Response('{}', 404),
        ),
      );
      addTearDown(api.close);
      final service = AdoptionsService(api);
      await expectLater(service.list(10, 0), throwsA(isA<ApiFailure>()));
      await expectLater(
        service.find('old'),
        throwsA(
          isA<ApiFailure>()
              .having((error) => error.status, 'status', 404)
              .having(
                (error) => error.message,
                'message',
                contains('ya no está disponible'),
              ),
        ),
      );
    },
  );
  test(
    'fallo de segunda página conserva resultados y reintenta mismo offset',
    () async {
      var failed = false;
      final offsets = <int>[];
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          final offset = int.parse(request.url.queryParameters['offset']!);
          offsets.add(offset);
          if (offset == 10 && !failed) {
            failed = true;
            return http.Response('{}', 503);
          }
          return http.Response(
            jsonEncode(
              offset == 0
                  ? List.generate(10, (index) => adoptionJson('item-$index'))
                  : [adoptionJson('last')],
            ),
            200,
          );
        }),
      );
      addTearDown(api.close);
      final list = PagedListController<AdoptionPublication>(
        fetchPage: AdoptionsService(api).list,
      );
      addTearDown(list.dispose);
      await list.refresh();
      await list.loadMore();
      expect(list.items.length, 10);
      expect(list.error, isNotNull);
      expect(list.pageError, true);
      await list.loadMore();
      expect(list.items.length, 11);
      expect(list.hasMore, false);
      expect(offsets, [0, 10, 10]);
    },
  );
  testWidgets('catálogo vacío y error inicial permiten reintentar', (
    tester,
  ) async {
    var requests = 0;
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient(
        (_) async => http.Response(
          requests++ == 0 ? '{}' : '[]',
          requests == 1 ? 503 : 200,
        ),
      ),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(body: AdoptionsScreen(service: AdoptionsService(api))),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver a intentar'));
    await tester.pumpAndSettle();
    expect(find.text('Pronto habrá nuevas historias'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'abre detalle, copia contacto y no muestra acciones ni datos privados',
    (tester) async {
      final clipboard = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            clipboard.add((call.arguments as Map)['text'] as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          final record = {
            ...adoptionJson(),
            'registroAdopcion': {'nombreAdoptante': 'Dato privado'},
          };
          return http.Response(
            jsonEncode(
              request.url.path.endsWith('/adopciones') ? [record] : record,
            ),
            200,
          );
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(body: AdoptionsScreen(service: AdoptionsService(api))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver adopción →'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle de adopción'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Copiar teléfono'),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Copiar teléfono'));
      await tester.pump();
      expect(clipboard, ['70000000']);
      await tester.scrollUntilVisible(
        find.text('Copiar dirección'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Copiar dirección'));
      await tester.pump();
      expect(clipboard, ['70000000', 'Calle Central 123']);
      expect(find.text('Dato privado'), findsNothing);
      expect(find.text('Registrar adopción'), findsNothing);
      expect(find.text('Editar datos'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'galería desplazable y requisitos opcionales caben en pantalla pequeña',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final record = adoptionJson();
      record['requisitos'] = null;
      record['mascota'] = {
        ...petJson(),
        'fotos': [
          {'id': 'photo-1', 'url': 'invalid', 'esPrincipal': true},
          {'id': 'photo-2', 'url': 'invalid', 'esPrincipal': false},
        ],
      };
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((_) async => http.Response(jsonEncode(record), 200)),
      );
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: AdoptionDetailScreen(
            id: 'publication-1',
            service: AdoptionsService(api),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Foto 1 de 2'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-280, 0));
      await tester.pumpAndSettle();
      expect(find.text('Foto 2 de 2'), findsOneWidget);
      final vertical = find
          .byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          )
          .first;
      await tester.scrollUntilVisible(
        find.textContaining('Consulta los requisitos'),
        250,
        scrollable: vertical,
      );
      expect(find.textContaining('Consulta los requisitos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('detalle retirado informa y permite reintentar', (tester) async {
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((_) async => http.Response('{}', 404)),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: AdoptionDetailScreen(id: 'old', service: AdoptionsService(api)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('ya no está disponible'), findsOneWidget);
    expect(find.text('Volver a intentar'), findsOneWidget);
    expect(find.text('Copiar teléfono'), findsNothing);
  });
}
