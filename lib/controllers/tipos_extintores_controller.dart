import 'package:flutter/foundation.dart';
import '../../api/tipos_extintores.dart';
import 'base_controller.dart';

class TiposExtintoresController extends BaseController {
  List<Map<String, dynamic>> dataTiposExtintores = [];
  final _tiposExtintoresService = TiposExtintoresService();

  Future<void> cargarTiposExtintores() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _tiposExtintoresService.listarTiposExtintores(),
      cacheBox: 'tiposExtintoresBox',
      cacheKey: 'tiposExtintores',
      onDataReceived: (data) {
        dataTiposExtintores = _formatModelTiposExtintores(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataTiposExtintores = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelTiposExtintores(data),
    );
  }

  Future<void> _saveToCache() async {
    await updateCache(
        'tiposExtintoresBox', 'tiposExtintores', dataTiposExtintores);
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
    dataTiposExtintores.insert(0, tempRecord);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'tiposExtintores/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _tiposExtintoresService.registraTiposExtintores(data);
        if (res['status'] == 200 || res['status'] == 201) {
          await cargarTiposExtintores();
          return true;
        }
        return false;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataTiposExtintores.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataTiposExtintores[index] = {...dataTiposExtintores[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'tiposExtintores/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res =
            await _tiposExtintoresService.actualizarTiposExtintores(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    // Optimistic Update
    dataTiposExtintores.removeWhere((e) => e['id'] == id);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'tiposExtintores/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res =
            await _tiposExtintoresService.eliminarTiposExtintores(id, {});
        return res.statusCode == 200;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataTiposExtintores.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataTiposExtintores[index] = {...dataTiposExtintores[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'tiposExtintores/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _tiposExtintoresService
            .actualizaDeshabilitarTiposExtintores(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final typeActions =
        actions.where((a) => a.url.startsWith('tiposExtintores/')).toList();

    for (var action in typeActions) {
      bool success = false;
      if (action.url == 'tiposExtintores/registrar') {
        final res =
            await _tiposExtintoresService.registraTiposExtintores(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('tiposExtintores/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _tiposExtintoresService.actualizarTiposExtintores(
            id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('tiposExtintores/eliminar/')) {
        final id = action.url.split('/').last;
        final res =
            await _tiposExtintoresService.eliminarTiposExtintores(id, {});
        success = res.statusCode == 200;
      } else if (action.url.startsWith('tiposExtintores/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res = await _tiposExtintoresService
            .actualizaDeshabilitarTiposExtintores(id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Tipo Extintor synced: ${action.id}");
        await cargarTiposExtintores(); // Refresh with server data
      }
    }
  }

  List<Map<String, dynamic>> _formatModelTiposExtintores(List<dynamic> data) {
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
