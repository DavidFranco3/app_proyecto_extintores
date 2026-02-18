import 'package:flutter/foundation.dart';
import '../../api/logs.dart';
import 'base_controller.dart';

class LogsController extends BaseController {
  List<Map<String, dynamic>> dataLogs = [];
  final _service = LogsService();

  Future<void> cargarLogs() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarLogs(),
      cacheBox: 'logsBox',
      cacheKey: 'logs',
      onDataReceived: (data) {
        dataLogs = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataLogs = List<Map<String, dynamic>>.from(
              cachedData.map((e) => Map<String, dynamic>.from(e)));
        }
      },
    );
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'folio': item['folio'],
        'usuario': item['usuario'],
        'correo': item['correo'],
        'dispositivo': item['dispositivo'],
        'ip': item['ip'],
        'descripcion': item['descripcion'],
        'detalles': item['detalles']?['mensaje'] ?? '',
        'estado': "true", // Logs are generally always "true" or just historical
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'logs/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _service.registraLog(data);
        return res.statusCode == 200 || res.statusCode == 201;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'logs/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizaDatosLog(id, data);
        return res.statusCode == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    return await performOfflineAction(
      url: 'logs/eliminar/$id',
      method: 'DELETE',
      body: {},
      apiCall: () async {
        final res = await _service.eliminaLogs(id);
        return res.statusCode == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final logActions = actions.where((a) => a.url.startsWith('logs/')).toList();

    for (var action in logActions) {
      bool success = false;
      if (action.url == 'logs/registrar') {
        final res = await _service.registraLog(action.body);
        success = res.statusCode == 200 || res.statusCode == 201;
      } else if (action.url.startsWith('logs/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _service.actualizaDatosLog(id, action.body);
        success = res.statusCode == 200;
      } else if (action.url.startsWith('logs/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _service.eliminaLogs(id);
        success = res.statusCode == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Log synced: ${action.id}");
      }
    }
  }

  Future<String> obtenIP() async {
    return await _service.obtenIP();
  }

  Future<Map<String, dynamic>> obtenerNumeroLog() async {
    return await _service.obtenerNumeroLog();
  }
}
