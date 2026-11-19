import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';
import 'package:smartpet_movil/features/auth/services/session.dart';
import 'package:smartpet_movil/features/mascotas/services/pets_service.dart';
import 'package:smartpet_movil/features/alertas/services/alerts_service.dart';

import 'support/fixtures.dart';

void main() {
  test(
    'login guarda token seguro; un rol diferente no obtiene sesión',
    () async {
      var role = 'CIUDADANO';
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          expect(request.headers.containsKey('authorization'), false);
          expect(jsonDecode(request.body), {
            'email': 'ana@example.com',
            'password': 'unchanged ',
          });
          return http.Response(
            jsonEncode({'access_token': 'jwt', 'usuario': profile(role: role)}),
            200,
          );
        }),
      );
      final store = MemoryTokenStore();
      final session = Session(api, store);
      await session.authenticate({
        'email': 'ana@example.com',
        'password': 'unchanged ',
      });
      expect(store.value, 'jwt');
      expect(session.user!.isCitizen, true);
      await session.logout();
      role = 'ADMIN';
      await expectLater(
        session.authenticate({
          'email': 'ana@example.com',
          'password': 'unchanged ',
        }),
        throwsA(isA<ApiFailure>()),
      );
      expect(store.value, isNull);
      expect(api.token, isNull);
      expect(session.user, isNull);
      session.dispose();
      api.close();
    },
  );

  test(
    'login y cierre notifican al dispositivo sin bloquear la sesión',
    () async {
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'access_token': 'jwt', 'usuario': profile()}),
            200,
          ),
        ),
      );
      final notifications = MemorySessionNotifications();
      final store = MemoryTokenStore();
      final session = Session(api, store, notifications: notifications);

      await session.authenticate({
        'email': 'ana@example.com',
        'password': '12345678',
      });
      expect(notifications.logins, 1);
      expect(api.token, 'jwt');

      notifications.failLogout = true;
      await session.logout();
      expect(notifications.logouts, 1);
      expect(api.token, isNull);
      expect(store.value, isNull);

      session.dispose();
      expect(notifications.disposed, true);
      api.close();
    },
  );

  test(
    'registro pendiente no guarda token y la verificación completa la sesión',
    () async {
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          if (request.url.path.endsWith('/auth/register')) {
            return http.Response(
              jsonEncode({
                'requiereVerificacion': true,
                'email': 'ana@example.com',
                'emailEnmascarado': 'an*@example.com',
                'correoEnviado': true,
              }),
              201,
            );
          }
          expect(request.url.path, endsWith('/auth/email/verify'));
          expect(jsonDecode(request.body), {
            'email': 'ana@example.com',
            'codigo': '123456',
          });
          return http.Response(
            jsonEncode({'access_token': 'jwt', 'usuario': profile()}),
            200,
          );
        }),
      );
      final store = MemoryTokenStore();
      final session = Session(api, store);

      final pending = await session.authenticate({
        'email': 'ana@example.com',
        'password': 'Password123',
      }, register: true);
      expect(pending?.maskedEmail, 'an*@example.com');
      expect(store.value, isNull);
      expect(session.user, isNull);

      await session.verifyEmail('ana@example.com', '123456');
      expect(store.value, 'jwt');
      expect(session.user?.isCitizen, true);
      session.dispose();
      api.close();
    },
  );

  test(
    'restauración conserva token si falla la red, y permite reintentar',
    () async {
      var offline = true;
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((request) async {
          expect(request.headers['authorization'], 'Bearer saved');
          if (offline) throw http.ClientException('offline');
          return http.Response(jsonEncode(profile()), 200);
        }),
      );
      final store = MemoryTokenStore('saved');
      final session = Session(api, store);
      await session.restore();
      expect(session.restoreError, isNotNull);
      expect(store.value, 'saved');
      expect(session.user, isNull);
      offline = false;
      await session.restore();
      expect(session.user!.nombre, 'Ana');
      expect(session.restoreError, isNull);
      session.dispose();
      api.close();
    },
  );

  test(
    '401 vigente cierra sesión; una respuesta antigua no cierra la nueva',
    () async {
      final pending = Completer<http.Response>();
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((_) => pending.future),
      );
      var invalidations = 0;
      api.onUnauthorized = (_) => invalidations++;
      api.token = 'old';
      final request = api.request('GET', '/auth/profile');
      final check = expectLater(
        request,
        throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 401)),
      );
      api.token = 'new';
      pending.complete(http.Response('{}', 401));
      await check;
      expect(invalidations, 0);
      expect(api.token, 'new');
      api.close();

      final expired = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((_) async => http.Response('{}', 401)),
      );
      final store = MemoryTokenStore('expired');
      final session = Session(expired, store);
      await session.restore();
      await Future<void>.delayed(Duration.zero);
      expect(session.restoring, false);
      expect(session.user, isNull);
      expect(store.value, isNull);
      expect(expired.token, isNull);
      session.dispose();
      expired.close();
    },
  );

  test(
    'respuesta de perfil pendiente no restaura una sesión cerrada',
    () async {
      final pending = Completer<http.Response>();
      final api = ApiClient(
        'https://example.com/api/v1',
        client: MockClient((_) => pending.future),
      )..token = 'jwt';
      final session = Session(api, MemoryTokenStore('jwt'));
      final updating = session.updateProfile({'nombre': 'Ana'});
      await session.logout();
      pending.complete(http.Response(jsonEncode(profile()), 200));
      await updating;
      expect(session.user, isNull);
      expect(api.token, isNull);
      session.dispose();
      api.close();
    },
  );

  test('subida multipart usa fotos, MIME real y Bearer; no envía rol ni propietario', () async {
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/mascotas');
        expect(request.headers['authorization'], 'Bearer jwt');
        expect(
          request.headers['content-type'],
          contains('multipart/form-data; boundary='),
        );
        final multipart = latin1.decode(request.bodyBytes);
        expect(multipart, contains('name="fotos"; filename="mascota.png"'));
        expect(multipart, contains('content-type: image/png'));
        expect(multipart, contains('name="especieId"'));
        expect(multipart, isNot(contains('name="rol"')));
        expect(multipart, isNot(contains('name="usuarioId"')));
        return http.Response(jsonEncode(petJson()), 201);
      }),
    )..token = 'jwt';
    final photo = await UploadPhoto.read(
      XFile.fromData(
        Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]),
        name: 'bad-name.jpg',
      ),
    );
    await PetsService(api).create({'nombre': 'Luna', 'especieId': 1}, [photo]);
    api.close();
  });

  test('rechaza formatos y tamaño antes de subir', () async {
    await expectLater(
      UploadPhoto.read(
        XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'fake.jpg'),
      ),
      throwsA(isA<ApiFailure>()),
    );
    await expectLater(
      UploadPhoto.read(
        XFile.fromData(Uint8List(5 * 1024 * 1024 + 1), name: 'huge.png'),
      ),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('alertas públicas sin token; historial propio con token; cierres con cuerpo vacío', () async {
    final captured = <http.Request>[];
    final api = ApiClient(
      'https://example.com/api/v1',
      client: MockClient((r) async {
        captured.add(r);
        return http.Response(r.method == 'GET' ? '[]' : '{}', 200);
      }),
    )..token = 'jwt';
    final service = AlertsService(api);
    await service.list(10, 20, mine: false);
    await service.list(10, 0, mine: true);
    await service.close('alert-1', resolved: true);
    expect(captured[0].headers['authorization'], isNull);
    expect(captured[0].url.queryParameters, {'limit': '10', 'offset': '20'});
    expect(captured[1].url.path, endsWith('/mis-alertas'));
    expect(captured[1].headers['authorization'], 'Bearer jwt');
    expect(captured[2].url.path, endsWith('/alert-1/resolver'));
    expect(captured[2].method, 'PATCH');
    expect(captured[2].body, '{}');
    api.close();
  });
}
