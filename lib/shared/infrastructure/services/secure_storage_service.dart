import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/services/storage_service.dart';

// La sesión (con el token) se guarda cifrada en el Keystore de Android.
class SecureStorageService implements StorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
