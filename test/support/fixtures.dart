import 'package:smartpet_movil/features/auth/services/session.dart';

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
