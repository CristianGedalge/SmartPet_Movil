import 'package:smartpet_movil/features/auth/services/session.dart';
import 'package:smartpet_movil/shared/services/api_client.dart';

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.value]);
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String token) async {
    value = token;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class MemorySessionNotifications implements SessionNotifications {
  int logins = 0;
  int logouts = 0;
  bool failLogout = false;
  bool disposed = false;

  @override
  Future<void> afterLogin(ApiClient api) async {
    logins++;
  }

  @override
  Future<void> beforeLogout(ApiClient api) async {
    logouts++;
    if (failLogout) throw StateError('push unavailable');
  }

  @override
  void dispose() {
    disposed = true;
  }
}

Map<String, dynamic> profile({String role = 'CIUDADANO'}) => {
  'id': 'citizen-1',
  'nombre': 'Ana',
  'apellido': 'Perez',
  'email': 'ana@example.com',
  'rol': role,
};
Map<String, dynamic> petJson() => {
  'id': 'pet-1',
  'nombre': 'Luna',
  'estado': true,
  'especie': {'id': 1, 'nombre': 'Perro'},
  'fotos': [],
};
