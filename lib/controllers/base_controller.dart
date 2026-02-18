import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';

abstract class BaseController extends ChangeNotifier {
  bool _loading = false;
  bool _isConnected = true;

  bool get loading => _loading;
  bool get isOffline => !_isConnected;

  final connectivity = ConnectivityService();
  final cache = CacheService();

  @protected
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// Generic fetch method implementing the "API with Hive fallback" pattern.
  /// [fetchFromApi] - Function to call the API service.
  /// [cacheBox] - Hive box name for caching.
  /// [cacheKey] - Key within the Hive box.
  /// [onDataReceived] - Callback to update the controller's state.
  /// [onCacheLoaded] - Callback to update state from cache.
  /// [formatToCache] - Optional function to format data before saving to Hive.
  Future<void> fetchData<T>({
    required Future<T> Function() fetchFromApi,
    required String cacheBox,
    required String cacheKey,
    required void Function(T data) onDataReceived,
    required void Function(dynamic cachedData) onCacheLoaded,
    dynamic Function(T data)? formatToCache,
  }) async {
    setLoading(true);

    try {
      _isConnected = await connectivity.isConnected;

      if (_isConnected) {
        final data = await fetchFromApi();
        if (data != null) {
          onDataReceived(data);
          // Save to cache
          final dataToCache =
              formatToCache != null ? formatToCache(data) : data;
          await cache.saveData(cacheBox, cacheKey, dataToCache);
        }
      } else {
        debugPrint("📶 Offline: Loading $cacheKey from $cacheBox");
        final cachedData = cache.getData(cacheBox, cacheKey);
        if (cachedData != null) {
          onCacheLoaded(cachedData);
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching $cacheKey: $e");
      // Fallback to cache even on error if it's the first time
      final cachedData = cache.getData(cacheBox, cacheKey);
      if (cachedData != null) {
        onCacheLoaded(cachedData);
      }
    } finally {
      setLoading(false);
    }
  }
}
