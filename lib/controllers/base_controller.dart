import 'package:flutter/material.dart';
import 'dart:async';
import '../services/connectivity_service.dart';
import '../services/cache_service.dart';
import '../services/offline_queue_service.dart';

abstract class BaseController extends ChangeNotifier {
  bool _loading = false;
  bool _isConnected = true;
  StreamSubscription? _connectivitySubscription;

  bool get loading => _loading;
  bool get isOffline => !_isConnected;

  final connectivity = ConnectivityService();
  final cache = CacheService();
  final queue = OfflineQueueService();

  BaseController() {
    _initConnectivity();
  }

  void _initConnectivity() async {
    // Check initial connectivity and sync if online
    _isConnected = await connectivity.isConnected;
    if (_isConnected) {
      syncPendingActions();
    }
    notifyListeners();

    _connectivitySubscription =
        connectivity.onInternetChanged.listen((hasInternet) {
      _isConnected = hasInternet;
      if (hasInternet) {
        debugPrint("🌐 Internet recovered! Triggering sync...");
        syncPendingActions();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @protected
  void setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  /// Generic fetch method implementing the "API with Hive fallback" pattern.
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
      final cachedData = cache.getData(cacheBox, cacheKey);
      if (cachedData != null) {
        onCacheLoaded(cachedData);
      }
    } finally {
      setLoading(false);
    }
  }

  /// Performs a write action with offline support.
  /// If offline, it queues the action for later.
  Future<bool> performOfflineAction({
    required String url,
    required String method,
    dynamic body,
    required Future<bool> Function() apiCall,
  }) async {
    _isConnected = await connectivity.isConnected;

    if (_isConnected) {
      try {
        final success = await apiCall();
        if (success) return true;
      } catch (e) {
        debugPrint("❌ API Call failed, queuing action: $e");
      }
    }

    // If we reach here, we are either offline or the API call failed
    await queue.queueAction(
      url: url,
      method: method,
      body: body,
    );
    notifyListeners();
    return false; // Returns false to indicate it was queued, not sent
  }

  /// Logic to sync pending actions from the queue.
  /// This should be overridden or extended by specific controllers to handle their specific API calls.
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    if (actions.isEmpty) return;

    debugPrint("🔄 Syncing ${actions.length} pending actions...");
    // Note: Specific controllers should implement the actual retry logic
    // or we can use a Centralized Sync Service if preferred.
  }

  /// Helper to update a specific cache box
  Future<void> updateCache(String box, String key, dynamic data) async {
    await cache.saveData(box, key, data);
  }
}
