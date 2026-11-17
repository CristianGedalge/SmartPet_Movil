import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartpet_movil/config/api_config.dart';
import 'package:smartpet_movil/features/auth/models/user_profile.dart';
import 'package:smartpet_movil/features/mascotas/models/pet.dart';
import 'package:smartpet_movil/features/alertas/models/lost_alert.dart';
import 'package:smartpet_movil/shared/controllers/paged_list_controller.dart';

void main() {
  test('config valida prefijo, HTTPS de producción y estilo seguro', () {
    const style = 'https://tiles.openfreemap.org/styles/liberty';
    expect(
      ApiConfig(
        apiUrl: 'http://10.0.2.2:3000/api/v1/',
        mapStyleUrl: style,
      ).apiUrl,
      'http://10.0.2.2:3000/api/v1',
    );
    expect(
      () => ApiConfig(
        apiUrl: 'http://localhost:3000/api/v1',
        mapStyleUrl: style,
        release: true,
      ),
      throwsFormatException,
    );
    expect(
      () => ApiConfig(apiUrl: 'https://api.example.com', mapStyleUrl: style),
      throwsFormatException,
    );
    expect(
      () => ApiConfig(
        apiUrl: 'https://user:secret@api.example.com/api/v1',
        mapStyleUrl: style,
      ),
      throwsFormatException,
    );
    expect(
      () => ApiConfig(
        apiUrl: 'https://api.example.com/api/v1',
        mapStyleUrl: 'http://map.example.com',
      ),
      throwsFormatException,
    );
  });

  test(
    'usuario conserva el rol validable y rechaza respuestas incompletas',
    () {
      final user = UserProfile.fromJson({
        'id': 'user',
        'nombre': 'Ana',
        'apellido': 'Pérez',
        'email': 'ana@example.com',
        'rol': 'CIUDADANO',
      });
      expect(user.isCitizen, isTrue);
      expect(user.initials, 'AP');
      expect(
        UserProfile.fromJson({
          'id': 'user',
          'nombre': 'Ana',
          'apellido': 'Pérez',
          'email': 'ana@example.com',
          'rol': 'ADMIN',
        }).isCitizen,
        isFalse,
      );
      expect(
        () => UserProfile.fromJson({'nombre': 'Ana'}),
        throwsFormatException,
      );
    },
  );

  test(
    'mascotas leen numeric como número o texto y encuentran la principal',
    () {
      final pet = Pet.fromJson({
        'id': 'pet',
        'nombre': 'Luna',
        'pesoKg': '4.25',
        'edadAproximadaMeses': 0,
        'fotos': [
          {
            'id': 'second',
            'url': 'https://images.test/2.jpg',
            'esPrincipal': false,
          },
          {
            'id': 'main',
            'url': 'https://images.test/1.jpg',
            'esPrincipal': true,
          },
        ],
      });
      expect(pet.pesoKg, 4.25);
      expect(pet.edadMeses, 0);
      expect(pet.ageLabel, '0 meses');
      expect(pet.mainPhoto?.id, 'main');
      expect(Pet.fromJson({'id': 'pet', 'nombre': 'Luna'}).mainPhoto, isNull);
    },
  );

  test('alertas públicas se leen sin propietario ni fotos privadas', () {
    final alert = LostAlert.fromJson({
      'id': 'alert',
      'mascotaId': 'pet',
      'fechaExtravio': '2020-01-01T12:00:00-04:00',
      'latitud': '0.00000000',
      'longitud': 0,
      'estado': 'ACTIVA',
      'mascota': {
        'id': 'pet',
        'nombre': 'Luna',
        'fotoPrincipal': {'id': 'photo', 'url': 'https://images.test/main.jpg'},
      },
    });
    expect(alert.latitude, 0);
    expect(alert.longitude, 0);
    expect(alert.isActive, isTrue);
    expect(alert.pet.mainPhoto?.url, 'https://images.test/main.jpg');
    expect(alert.lostAt.toUtc().hour, 16);
    expect(AlertStatus.parse('NEW_UNKNOWN_STATE'), AlertStatus.unknown);
  });

  test(
    'paginación conserva filtros, offset y datos al fallar la página siguiente',
    () async {
      final offsets = <int>[];
      var fail = false;
      final list = PagedListController<int>(
        pageSize: 2,
        fetchPage: (limit, offset) async {
          offsets.add(offset);
          if (fail) throw Exception('Sin conexión');
          return offset == 0 ? [1, 2] : [3];
        },
      );
      await list.refresh();
      fail = true;
      await list.loadMore();
      expect(list.items, [1, 2]);
      expect(list.pageError, isTrue);
      fail = false;
      await list.loadMore();
      expect(list.items, [1, 2, 3]);
      expect(list.hasMore, isFalse);
      expect(offsets, [0, 2, 2]);
      list.dispose();
    },
  );

  test('una respuesta antigua no sobrescribe una recarga reciente', () async {
    final old = Completer<List<int>>();
    var calls = 0;
    final list = PagedListController<int>(
      fetchPage: (_, _) => ++calls == 1 ? old.future : Future.value([2]),
    );
    final first = list.refresh();
    await list.refresh();
    old.complete([1]);
    await first;
    expect(list.items, [2]);
    expect(list.loading, isFalse);
    list.dispose();
  });

  test(
    'completar una solicitud tras desmontar no notifica ni cambia datos',
    () async {
      final pending = Completer<List<int>>();
      final list = PagedListController<int>(
        fetchPage: (_, _) => pending.future,
      );
      final load = list.refresh();
      list.dispose();
      pending.complete([1]);
      await load;
      expect(list.items, isEmpty);
      await list.refresh();
    },
  );
}
