import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartpet_movil/features/mascotas/models/pet.dart';
import 'package:smartpet_movil/features/mascotas/screens/pet_poster_screen.dart';
import 'package:smartpet_movil/features/mascotas/services/pet_poster_service.dart';
import 'package:smartpet_movil/features/mascotas/services/pet_poster_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pet = Pet(
    id: 'pet-1',
    nombre: 'Luna',
    active: true,
    photos: [],
    species: Species(id: 1, nombre: 'Perro'),
    razaNombre: 'Mestiza',
    sexo: 'HEMBRA',
    color: 'Blanco y café',
    edadMeses: 18,
  );

  test('genera un PNG vertical aun cuando la mascota no tiene foto', () async {
    final bytes = await PetPosterService().generate(pet);

    expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, PetPosterService.width);
    expect(frame.image.height, PetPosterService.height);
    frame.image.dispose();
    codec.dispose();
  });

  test(
    'usa el marcador cuando la fotografía remota no está disponible',
    () async {
      const petWithPhoto = Pet(
        id: 'pet-2',
        nombre: 'Toby',
        active: true,
        photos: [
          PetPhoto(
            id: 'photo-1',
            url: 'https://images.example/not-found.jpg',
            isMain: true,
          ),
        ],
      );
      final poster = await PetPosterService(imageLoader: (_) async => null)
          .generate(petWithPhoto);

      expect(poster.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    },
  );

  testWidgets('muestra progreso y la vista previa generada', (tester) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1cAAAAASUVORK5CYII=',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: PetPosterScreen(pet: pet, posterService: _PosterService(bytes)),
      ),
    );

    expect(find.text('Generando afiche…'), findsOneWidget);
    await tester.pump();

    expect(find.byKey(const Key('pet-poster-preview')), findsOneWidget);
    expect(find.textContaining('Afiche listo en formato PNG'), findsOneWidget);
    expect(find.text('Compartir o guardar'), findsOneWidget);
    expect(find.text('Volver a generar'), findsOneWidget);
  });

  testWidgets('comparte el PNG generado con el nombre de la mascota', (
    tester,
  ) async {
    final bytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jN1cAAAAASUVORK5CYII=',
    );
    final shareService = _ShareService();
    await tester.pumpWidget(
      MaterialApp(
        home: PetPosterScreen(
          pet: pet,
          posterService: _PosterService(bytes),
          shareService: shareService,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Compartir o guardar'));
    await tester.pump();

    expect(shareService.receivedBytes, same(bytes));
    expect(shareService.receivedPetName, 'Luna');
  });

  test('genera un nombre de archivo seguro y reconocible', () {
    expect(
      PetPosterShareService().fileNameFor('  Muñeca Café  '),
      'afiche-muneca-cafe.png',
    );
  });
}

class _PosterService extends PetPosterService {
  _PosterService(this.bytes);
  final Uint8List bytes;

  @override
  Future<Uint8List> generate(Pet pet) async => bytes;
}

class _ShareService extends PetPosterShareService {
  Uint8List? receivedBytes;
  String? receivedPetName;

  @override
  Future<PetPosterShareResult> share({
    required Uint8List bytes,
    required String petName,
    ui.Rect? sharePositionOrigin,
  }) async {
    receivedBytes = bytes;
    receivedPetName = petName;
    return PetPosterShareResult.opened;
  }
}
