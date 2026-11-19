import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/busqueda_visual/screens/visual_search_screen.dart';
import 'package:smartpet_movil/features/busqueda_visual/services/visual_search_service.dart';
import 'package:smartpet_movil/features/avistamientos/services/sightings_service.dart';
import 'package:smartpet_movil/features/mascotas/services/pets_service.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1cAAAAASUVORK5CYII=',
);
Map<String, dynamic> result({bool empty = false}) => {
  'aviso': 'Posibles coincidencias, no identidad confirmada.',
  'fotosNoProcesadas': 0,
  'resultados': empty
      ? []
      : [
          {
            'similitud': .8,
            'avistamiento': {
              'id': 'sighting-1',
              'especieId': 1,
              'especie': {'id': 1, 'nombre': 'Perro'},
              'descripcion': 'Visto cerca de la plaza',
              'direccion': 'Plaza central',
              'fechaAvistamiento': '2026-11-18T12:00:00Z',
              'latitud': -17.78,
              'longitud': -63.18,
              'estado': 'ACTIVO',
              'fotos': [],
            },
          },
        ],
};

class GalleryPicker extends ImagePicker {
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async => [XFile.fromData(png, name: 'pet.png')];
}

void main() {
  test('envía fotos multipart con JWT y especie, interpreta candidatos sin porcentajes', () async {
    final api = ApiClient(
      'https://example.test/api/v1',
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer citizen-token');
        expect(request.url.path, '/api/v1/busqueda-visual/avistamientos');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data'),
        );
        expect(
          String.fromCharCodes(request.bodyBytes),
          contains('name="especieId"'),
        );
        expect(
          String.fromCharCodes(request.bodyBytes),
          contains('name="fotos"'),
        );
        return http.Response(jsonEncode(result()), 201);
      }),
    )..token = 'citizen-token';
    final response = await VisualSearchService(api)
        .search(1, [UploadPhoto(png, 'image/png', 'a.png')]);
    expect(response.matches.single.sighting.id, 'sighting-1');
    expect(response.notice, contains('no identidad confirmada'));
    api.close();
  });
  test('valida fotos y propaga indisponibilidad del servicio', () async {
    final api = ApiClient(
      'https://example.test/api/v1',
      client: MockClient((_) async => http.Response('{}', 503)),
    )..token = 'token';
    final service = VisualSearchService(api);
    await expectLater(service.search(1, []), throwsA(isA<ApiFailure>()));
    await expectLater(
      service.search(1, [const UploadPhoto([], 'image/png', 'a.png')]),
      throwsA(isA<ApiFailure>()),
    );
    await expectLater(
      service.search(1, [UploadPhoto(png, 'image/png', 'a.png')]),
      throwsA(isA<ApiFailure>()),
    );
    api.close();
  });

  testWidgets(
    'selecciona foto, conserva datos ante error, reintenta y muestra candidatos',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var attempts = 0;
      final pending = Completer<http.Response>();
      final api = ApiClient(
        'https://example.test/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/especies')) {
            return http.Response(
              '[{"id":1,"nombre":"Perro"},{"id":2,"nombre":"Gato"}]',
              200,
            );
          }
          attempts++;
          if (attempts == 1) return http.Response('{}', 503);
          return pending.future;
        }),
      )..token = 'token';
      addTearDown(api.close);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: VisualSearchScreen(
            service: VisualSearchService(api),
            sightings: SightingsService(api),
            styleUrl: 'https://example.test/style',
            imagePicker: GalleryPicker(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buscar coincidencias'));
      await tester.pumpAndSettle();
      expect(
        find.text('Selecciona Perro o Gato y agrega al menos una foto.'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perro').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar fotos'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      expect(find.text('1/5 fotos'), findsOneWidget);
      await tester.tap(find.text('Buscar coincidencias'));
      await tester.pumpAndSettle();
      expect(
        find.text('El servicio no está disponible. Intenta nuevamente.'),
        findsOneWidget,
      );
      expect(find.text('1/5 fotos'), findsOneWidget);
      await tester.ensureVisible(find.text('Volver a intentar'));
      await tester.tap(find.text('Volver a intentar'));
      await tester.pump();
      expect(find.textContaining('Comparando fotografías'), findsOneWidget);
      pending.complete(http.Response(jsonEncode(result()), 201));
      await tester.pumpAndSettle();
      expect(find.text('1 posible coincidencia'), findsOneWidget);
      expect(find.text('Posible coincidencia 1'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      await tester.ensureVisible(find.byTooltip('Quitar foto 1'));
      await tester.tap(find.byTooltip('Quitar foto 1'));
      await tester.pumpAndSettle();
      expect(find.text('Posible coincidencia 1'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
