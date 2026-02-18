import 'package:flutter/foundation.dart';
import '../../api/extintores.dart';
import 'base_controller.dart';

class ExtintoresController extends BaseController {
  List<Map<String, dynamic>> dataExtintores = [];
  final _extintoresService = ExtintoresService();

  Future<void> cargarExtintores() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _extintoresService.listarExtintores(),
      cacheBox: 'extintoresBox',
      cacheKey: 'extintores',
      onDataReceived: (data) {
        dataExtintores = _formatModelExtintores(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataExtintores = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModelExtintores(data),
    );
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'extintores/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _extintoresService.registraExtintores(data);
        return res['status'] == 200 || res['status'] == 201;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'extintores/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _extintoresService.actualizarExtintores(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    return await performOfflineAction(
      url: 'extintores/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res = await _extintoresService.eliminarExtintores(id, {});
        return res['status'] == 200;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'extintores/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res =
            await _extintoresService.actualizaDeshabilitarExtintores(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final extActions =
        actions.where((a) => a.url.startsWith('extintores/')).toList();

    for (var action in extActions) {
      bool success = false;
      if (action.url == 'extintores/registrar') {
        final res = await _extintoresService.registraExtintores(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('extintores/actualizar/')) {
        final id = action.url.split('/').last;
        final res =
            await _extintoresService.actualizarExtintores(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('extintores/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _extintoresService.eliminarExtintores(id, {});
        success = res['status'] == 200;
      } else if (action.url.startsWith('extintores/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res = await _extintoresService.actualizaDeshabilitarExtintores(
            id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Extintor synced: ${action.id}");
      }
    }
  }

  List<Map<String, dynamic>> _formatModelExtintores(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'numeroSerie': item['numeroSerie'],
        'idTipoExtintor': item['idTipoExtintor'],
        'extintor': item['tipoExtintor']['nombre'],
        'capacidad': item['capacidad'],
        'ultimaRecarga': item['ultimaRecarga'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
