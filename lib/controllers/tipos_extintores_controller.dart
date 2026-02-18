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

  Future<bool> registrar(Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'tiposExtintores/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _tiposExtintoresService.registraTiposExtintores(data);
        return res['status'] == 200 || res['status'] == 201;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
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
