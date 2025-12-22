import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/models/auth_session.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _storage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _sessionKey = 'logus_session';

  Future<void> saveSession(AuthSession session) async {
    final payload = jsonEncode(session.toJson());
    await _storage.write(key: _sessionKey, value: payload);
  }

  Future<AuthSession?> readSession() async {
    final payload = await _storage.read(key: _sessionKey);
    if (payload == null) {
      return null;
    }
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return AuthSession.fromJson(decoded);
  }

  Future<void> clearSession() => _storage.delete(key: _sessionKey);
}
