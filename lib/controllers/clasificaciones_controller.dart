import 'package:flutter/foundation.dart';
import '../../api/clasificaciones.dart';
import 'base_controller.dart';

class ClasificacionesController extends BaseController {
  List<Map<String, dynamic>> dataClasificaciones = [];
  final _clasificacionesService = ClasificacionesService();

  Future<void> cargarClasificaciones() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _clasificacionesService.listarClasificaciones(),
      cacheBox: 'clasificacionesBox',
      cacheKey: 'clasificaciones',
      onDataReceived: (data) {
        dataClasificaciones = _formatModelClasificaciones(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataClasificaciones = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelClasificaciones(data),
    );
  }

  Future<void> _saveToCache() async {
    await updateCache(
        'clasificacionesBox', 'clasificaciones', dataClasificaciones);
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    // Optimistic Update
    final tempRecord = {
      ...data,
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'estado': 'true',
      'isOptimistic': true,
      'createdAt': DateTime.now().toIso8601String(),
    };
    dataClasificaciones.insert(0, tempRecord);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'clasificaciones/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res =
            await _clasificacionesService.registrarClasificaciones(data);
        if (res['status'] == 200 || res['status'] == 201) {
          await cargarClasificaciones();
          return true;
        }
        return false;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataClasificaciones.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataClasificaciones[index] = {...dataClasificaciones[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'clasificaciones/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res =
            await _clasificacionesService.actualizarClasificaciones(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    // Optimistic Update
    dataClasificaciones.removeWhere((e) => e['id'] == id);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'clasificaciones/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res = await _clasificacionesService.eliminarClasificaciones(id);
        return res['success'] == true;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataClasificaciones.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataClasificaciones[index] = {...dataClasificaciones[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'clasificaciones/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res =
            await _clasificacionesService.deshabilitarClasificaciones(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final clasActions =
        actions.where((a) => a.url.startsWith('clasificaciones/')).toList();

    for (var action in clasActions) {
      bool success = false;
      if (action.url == 'clasificaciones/registrar') {
        final res =
            await _clasificacionesService.registrarClasificaciones(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('clasificaciones/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _clasificacionesService.actualizarClasificaciones(
            id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('clasificaciones/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _clasificacionesService.eliminarClasificaciones(id);
        success = res['success'] == true;
      } else if (action.url.startsWith('clasificaciones/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res = await _clasificacionesService.deshabilitarClasificaciones(
            id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Clasificación synced: ${action.id}");
        await cargarClasificaciones(); // Refresh with server data
      }
    }
  }

  List<Map<String, dynamic>> _formatModelClasificaciones(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
