import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageUtil {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<void> storeNewKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<Map<String, String>> getAllStoredData() async {
    return await _storage.readAll();
  }

  static Future<String?> getValue(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> clearStorage() async {
    await _storage.deleteAll();
  }
}
