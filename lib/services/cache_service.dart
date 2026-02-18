import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Future<void> saveData(String boxName, String key, dynamic data) async {
    final box = Hive.box(boxName);
    await box.put(key, data);
  }

  T? getData<T>(String boxName, String key) {
    if (!Hive.isBoxOpen(boxName)) return null;
    final box = Hive.box(boxName);
    return box.get(key) as T?;
  }

  Future<void> clearData(String boxName, String key) async {
    final box = Hive.box(boxName);
    await box.delete(key);
  }
}
