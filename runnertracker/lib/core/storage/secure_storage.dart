import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const String jwtKey = 'jwt';

  final FlutterSecureStorage _storage;

  Future<String?> readJwt() {
    return _storage.read(key: jwtKey);
  }

  Future<void> writeJwt(String token) {
    return _storage.write(key: jwtKey, value: token);
  }

  Future<void> deleteJwt() {
    return _storage.delete(key: jwtKey);
  }

  Future<void> clear() {
    return _storage.deleteAll();
  }
}
