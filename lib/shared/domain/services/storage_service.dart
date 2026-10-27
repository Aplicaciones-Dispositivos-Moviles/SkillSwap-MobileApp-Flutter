// Almacenamiento clave-valor en el teléfono (la implementación decide dónde).
abstract class StorageService {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
