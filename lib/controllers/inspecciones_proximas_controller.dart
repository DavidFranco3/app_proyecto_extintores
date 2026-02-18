import 'package:flutter/foundation.dart';
import '../../api/inspecciones_proximas.dart';
import 'base_controller.dart';

class InspeccionesProximasController extends BaseController {
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  final _service = InspeccionesProximasService();

  Future<void> cargarInspeccionesProximas() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarInspeccionesProximas(),
      cacheBox: 'inspeccionesProximasBox',
      cacheKey: 'inspecciones_proximas',
      onDataReceived: (data) {
        dataInspeccionesProximas = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataInspeccionesProximas = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModel(data),
    );
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'idCliente': item['idCliente'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['frecuencia']['nombre'],
        'cliente': item['cliente']['nombre'],
        'proximaInspeccion': item['nuevaInspeccion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'inspecciones_proximas/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _service.registraInspeccionesProximas(data);
        return res['status'] == 200 || res['status'] == 201;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'inspecciones_proximas/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizarInspeccionesProximas(id, data);
        return res.statusCode == 200;
      },
    );
  }

  Future<bool> eliminar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'inspecciones_proximas/eliminar/$id',
      method: 'DELETE',
      body: data,
      apiCall: () async {
        final res = await _service.eliminarInspeccionesProximas(id, data);
        return res.statusCode == 200;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'inspecciones_proximas/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res =
            await _service.actualizaDeshabilitarInspeccionesProximas(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final proxActions = actions
        .where((a) => a.url.startsWith('inspecciones_proximas/'))
        .toList();

    for (var action in proxActions) {
      bool success = false;
      if (action.url == 'inspecciones_proximas/registrar') {
        final res = await _service.registraInspeccionesProximas(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('inspecciones_proximas/actualizar/')) {
        final id = action.url.split('/').last;
        final res =
            await _service.actualizarInspeccionesProximas(id, action.body);
        success = res.statusCode == 200;
      } else if (action.url.startsWith('inspecciones_proximas/eliminar/')) {
        final id = action.url.split('/').last;
        final res =
            await _service.eliminarInspeccionesProximas(id, action.body);
        success = res.statusCode == 200;
      } else if (action.url.startsWith('inspecciones_proximas/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res = await _service.actualizaDeshabilitarInspeccionesProximas(
            id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Proxima Inspeccion synced: ${action.id}");
      }
    }
  }
}
