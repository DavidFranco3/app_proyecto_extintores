import 'package:flutter/foundation.dart';
import '../api/frecuencias.dart';
import 'base_controller.dart';

class FrecuenciasController extends BaseController {
  List<Map<String, dynamic>> dataFrecuencias = [];
  final _frecuenciasService = FrecuenciasService();

  Future<void> cargarFrecuencias() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _frecuenciasService.listarFrecuencias(),
      cacheBox: 'frecuenciasBox',
      cacheKey: 'frecuencias',
      onDataReceived: (data) {
        dataFrecuencias = _formatModelFrecuencias(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataFrecuencias = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelFrecuencias(data),
    );
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'frecuencias/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _frecuenciasService.registraFrecuencias(data);
        return res['status'] == 200 || res['status'] == 201;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'frecuencias/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _frecuenciasService.actualizarFrecuencias(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    return await performOfflineAction(
      url: 'frecuencias/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res = await _frecuenciasService.eliminarFrecuencias(id, {});
        return res['status'] == 200;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'frecuencias/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _frecuenciasService.actualizaDeshabilitarFrecuencias(
            id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final freqActions =
        actions.where((a) => a.url.startsWith('frecuencias/')).toList();

    for (var action in freqActions) {
      bool success = false;
      if (action.url == 'frecuencias/registrar') {
        final res = await _frecuenciasService.registraFrecuencias(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('frecuencias/actualizar/')) {
        final id = action.url.split('/').last;
        final res =
            await _frecuenciasService.actualizarFrecuencias(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('frecuencias/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _frecuenciasService.eliminarFrecuencias(id, {});
        success = res['status'] == 200;
      } else if (action.url.startsWith('frecuencias/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res = await _frecuenciasService.actualizaDeshabilitarFrecuencias(
            id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Frecuencia synced: ${action.id}");
      }
    }
  }

  List<Map<String, dynamic>> _formatModelFrecuencias(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
              'cantidadDias': item['cantidadDias'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }
}
