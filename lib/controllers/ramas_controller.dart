import 'package:flutter/foundation.dart';
import '../api/ramas.dart';
import 'base_controller.dart';

class RamasController extends BaseController {
  List<Map<String, dynamic>> dataRamas = [];
  final _ramasService = RamasService();

  Future<void> cargarRamas() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _ramasService.listarRamas(),
      cacheBox: 'ramasBox',
      cacheKey: 'ramas',
      onDataReceived: (data) {
        dataRamas = _formatModelRamas(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataRamas = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelRamas(data),
    );
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'ramas/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _ramasService.registrarRamas(data);
        return res['status'] == 200 || res['status'] == 201;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'ramas/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _ramasService.actualizarRamas(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    return await performOfflineAction(
      url: 'ramas/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res = await _ramasService.eliminarRamas(id);
        return res['success'] == true;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'ramas/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _ramasService.deshabilitarRamas(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final ramaActions =
        actions.where((a) => a.url.startsWith('ramas/')).toList();

    for (var action in ramaActions) {
      bool success = false;
      if (action.url == 'ramas/registrar') {
        final res = await _ramasService.registrarRamas(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('ramas/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _ramasService.actualizarRamas(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('ramas/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _ramasService.eliminarRamas(id);
        success = res['success'] == true;
      } else if (action.url.startsWith('ramas/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res = await _ramasService.deshabilitarRamas(id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Rama synced: ${action.id}");
      }
    }
  }

  List<Map<String, dynamic>> _formatModelRamas(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
