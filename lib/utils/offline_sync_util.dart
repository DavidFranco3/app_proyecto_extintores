import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/offline_queue_service.dart';
import '../services/connectivity_service.dart';

class OfflineSyncUtil {
  static final OfflineSyncUtil _instance = OfflineSyncUtil._internal();
  factory OfflineSyncUtil() => _instance;
  OfflineSyncUtil._internal();

  final _queue = OfflineQueueService();
  final connectivity = ConnectivityService();
  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  void init() {
    _updatePendingCount();
    // Listen to the queue box for changes
    Hive.box(OfflineQueueService.boxName)
        .listenable()
        .addListener(_updatePendingCount);
  }

  Future<void> _updatePendingCount() async {
    try {
      pendingCount.value = await _queue.queueLength;
    } catch (e) {
      debugPrint("Error calculando pendientes: $e");
    }
  }

  Future<bool> verificarConexion() async {
    return await connectivity.hasRealInternet;
  }

  Future<void> sincronizarTodo() async {
    if (!await verificarConexion()) return;
    debugPrint(
        "🔄 Global sync triggered via OfflineSyncUtil. Note: Controllers now handle their own sync logic.");
  }
}
