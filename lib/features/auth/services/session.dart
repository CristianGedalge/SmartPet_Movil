import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../shared/models/json_values.dart';
import '../../../shared/services/api_client.dart';
import '../models/user_profile.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  final _storage = const FlutterSecureStorage();
  static const _key = 'smartpet_access_token';
  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class Session extends ChangeNotifier {
  Session(this.api, this.store) {
    api.onUnauthorized = (_) {
      unawaited(logout());
    };
  }
  final ApiClient api;
  final TokenStore store;
  UserProfile? user;
  bool restoring = true;
  String? restoreError;
  int _generation = 0;
  bool _disposed = false;
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> _storageQueue = Future<void>.value();
  Future<void> _persist(Future<void> Function() operation) {
    final next = _storageQueue.then((_) => operation());
    _storageQueue = next.catchError((Object _) {});
    return next;
  }

  Future<void> restore() async {
    restoring = true;
    restoreError = null;
    notifyListeners();
    final generation = ++_generation;
    try {
      final storedToken = await store.read();
      if (generation != _generation) return;
      api.token = storedToken;
      if (api.token != null) {
        final profile = UserProfile.fromJson(
          jsonObject(await api.request('GET', '/auth/profile')),
        );
        if (generation != _generation) return;
        _requireCitizen(profile);
        user = profile;
      }
    } catch (error) {
      if (generation != _generation) return;
      if (error is ApiFailure && error.status == 403) {
        await logout();
      } else {
        restoreError = error is ApiFailure
            ? error.message
            : 'No se pudo recuperar la sesión guardada. Intenta nuevamente.';
      }
    } finally {
      if (generation == _generation) {
        restoring = false;
        notifyListeners();
      }
    }
  }

  void _requireCitizen(UserProfile profile) {
    if (!profile.isCitizen) {
      throw const ApiFailure(
        'Esta app es para ciudadanos. Ingresa con una cuenta de ciudadano.',
        status: 403,
      );
    }
  }

  Future<void> authenticate(
    Map<String, dynamic> data, {
    bool register = false,
  }) async {
    final generation = ++_generation;
    final result = jsonObject(
      await api.request(
        'POST',
        register ? '/auth/register' : '/auth/login',
        body: data,
        authenticated: false,
      ),
    );
    final profile = UserProfile.fromJson(jsonObject(result['usuario']));
    _requireCitizen(profile);
    final token = requiredString(result, 'access_token');
    if (generation != _generation || _disposed) return;
    try {
      await _persist(() => store.write(token));
    } catch (_) {
      throw const ApiFailure(
        'No se pudo guardar la sesión de forma segura. Intenta nuevamente.',
      );
    }
    if (generation != _generation || _disposed) return;
    api.token = token;
    user = profile;
    restoring = false;
    restoreError = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final generation = _generation;
    final profile = UserProfile.fromJson(
      jsonObject(await api.request('PATCH', '/auth/profile', body: data)),
    );
    _requireCitizen(profile);
    if (generation != _generation || _disposed) return;
    user = profile;
    notifyListeners();
  }

  Future<void> logout() async {
    ++_generation;
    api.token = null;
    user = null;
    restoring = false;
    restoreError = null;
    notifyListeners();
    try {
      await _persist(store.clear);
    } catch (_) {
      restoreError = 'No se pudo borrar la sesión guardada. Vuelve a intentar cerrar sesión.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    api.onUnauthorized = null;
    super.dispose();
  }
}
