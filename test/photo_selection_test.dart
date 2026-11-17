import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartpet_movil/config/app_theme.dart';
import 'package:smartpet_movil/features/mascotas/screens/pet_form_screen.dart';
import 'package:smartpet_movil/features/mascotas/services/pets_service.dart';
import 'package:smartpet_movil/features/mascotas/widgets/photo_picker.dart';
import 'package:smartpet_movil/features/mascotas/widgets/photo_selection.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

import 'support/fixtures.dart';

final png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1cAAAAASUVORK5CYII=',
);
UploadPhoto photo() => UploadPhoto(png, 'image/png', 'photo.png');

class FakePicker extends ImagePicker {
  int? requestedLimit;
  PlatformException? error;
  List<XFile> files = [];
  @override
  Future<List<XFile>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
    bool requestFullMetadata = true,
  }) async {
    requestedLimit = limit;
    if (error != null) throw error!;
    return files;
  }

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (error != null) throw error!;
    return files.firstOrNull;
  }
}

class MisreportedFile extends XFile {
  MisreportedFile() : super.fromData(Uint8List(5 * 1024 * 1024 + 1));
  @override
  Future<int> length() async => 1;
}

void main() {
  test('valida tamaño real tras leer y rechaza archivos vacíos', () async {
    await expectLater(
      UploadPhoto.read(MisreportedFile()),
      throwsA(isA<ApiFailure>()),
    );
    await expectLater(
      UploadPhoto.read(XFile.fromData(Uint8List(0))),
      throwsA(isA<ApiFailure>()),
    );
    final valid = await UploadPhoto.read(
      XFile.fromData(png, name: 'fake.heic'),
    );
    expect(valid.mime, 'image/png');
  });

  Future<void> openPicker(
    WidgetTester tester,
    FakePicker picker,
    void Function(Future<List<UploadPhoto>>) started, {
    int available = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => started(
                pickPhotos(context, available: available, imagePicker: picker),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('galería conoce el límite restante y cancelar no agrega fotos', (
    tester,
  ) async {
    final picker = FakePicker();
    late Future<List<UploadPhoto>> result;
    await openPicker(tester, picker, (value) => result = value);
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();
    expect(await result, isEmpty);
    expect(picker.requestedLimit, 1);
  });

  testWidgets('revalida el máximo si una plataforma ignora el límite', (
    tester,
  ) async {
    final picker = FakePicker()
      ..files = [XFile.fromData(png), XFile.fromData(png)];
    late Future<List<UploadPhoto>> result;
    await openPicker(tester, picker, (value) => result = value);
    final expectation = expectLater(result, throwsA(isA<ApiFailure>()));
    await tester.tap(find.text('Elegir de la galería'));
    await tester.pumpAndSettle();
    await expectation;
  });

  for (final source in ['cámara', 'galería']) {
    testWidgets(
      'permiso de $source denegado devuelve mensaje sin excepción técnica',
      (tester) async {
        final picker = FakePicker()
          ..error = PlatformException(
            code: source == 'cámara'
                ? 'camera_access_denied'
                : 'photo_access_denied',
          );
        late Future<List<UploadPhoto>> result;
        await openPicker(tester, picker, (value) => result = value);
        final expectation = expectLater(
          result,
          throwsA(
            isA<ApiFailure>().having(
              (error) => error.message,
              'mensaje',
              contains('ajustes de SmartPet'),
            ),
          ),
        );
        await tester.tap(
          find.text(
            source == 'cámara' ? 'Tomar una foto' : 'Elegir de la galería',
          ),
        );
        await tester.pumpAndSettle();
        await expectation;
      },
    );
  }

  testWidgets(
    'contador, límite y quitar la foto correcta funcionan en pantalla pequeña',
    (tester) async {
      var photos = List.generate(5, (_) => photo());
      final removed = photos[1];
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (context, update) => PhotoSelection(
                    photos: photos,
                    onPick: () {},
                    onRemove: (index) =>
                        update(() => photos = [...photos]..removeAt(index)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5/5 fotos'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Límite de 5 fotos'),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.byTooltip('Quitar foto 2'));
      await tester.pumpAndSettle();
      expect(photos.contains(removed), false);
      expect(find.text('4/5 fotos'), findsOneWidget);
      expect(find.text('Foto principal'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'mascotas bloquea doble selección y envío mientras prepara fotos',
    (tester) async {
      final pending = Completer<List<UploadPhoto>>();
      var openings = 0;
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient(
          (_) async => http.Response('[{"id":1,"nombre":"Perro"}]', 200),
        ),
      )..token = 'jwt';
      await tester.pumpWidget(
        MaterialApp(
          home: PetFormScreen(
            service: PetsService(api),
            photoPicker: (_, available) {
              openings++;
              return pending.future;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Agregar fotos'));
      await tester.tap(find.text('Agregar fotos'));
      await tester.pump();
      expect(find.text('Preparando fotos…'), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Guardar mascota'),
      );
      expect(save.onPressed, isNull);
      final picking = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Preparando fotos…'),
      );
      expect(picking.onPressed, isNull);
      expect(openings, 1);
      pending.complete([photo()]);
      await tester.pumpAndSettle();
      expect(find.text('1/5 fotos'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      api.close();
    },
  );

  testWidgets('multipart tolera una subida que tarda más de 45 segundos', (
    tester,
  ) async {
    final response = Completer<http.Response>();
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((_) => response.future),
    )..token = 'jwt';
    Object? failure;
    final request = PetsService(api)
        .create({'nombre': 'Luna', 'especieId': 1}, [photo()]);
    final observed = request.then(
      (_) {},
      onError: (Object error) {
        failure = error;
      },
    );
    await tester.pump(const Duration(seconds: 50));
    expect(failure, isNull);
    response.complete(http.Response(jsonEncode(petJson()), 201));
    await tester.pump();
    await observed;
    expect(failure, isNull);
    api.close();
  });
}
