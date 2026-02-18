import 'package:flutter/foundation.dart';
import '../api/clientes.dart';
import '../api/models/cliente_model.dart';
import 'base_controller.dart';

class ClientesController extends BaseController {
  List<ClienteModel> dataClientes = [];
  final _clientesService = ClientesService();

  Future<void> cargarClientes() async {
    await fetchData<List<ClienteModel>>(
      fetchFromApi: () => _clientesService.listarClientes(),
      cacheBox: 'clientesBox',
      cacheKey: 'clientes',
      onDataReceived: (data) {
        dataClientes = data;
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataClientes = cachedData
              .map((item) =>
                  ClienteModel.fromJson(Map<String, dynamic>.from(item as Map)))
              .where((item) => item.estado == "true")
              .toList();
        }
      },
      formatToCache: (data) => data.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _saveToCache() async {
    await updateCache('clientesBox', 'clientes',
        dataClientes.map((e) => e.toJson()).toList());
  }

  Future<bool> registrar(Map<String, dynamic> data) async {
    // Optimistic Update
    final tempClient = ClienteModel.fromJson({
      ...data,
      '_id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'estado': 'true',
      'isOptimistic': true,
      'createdAt': DateTime.now().toIso8601String(),
    });
    dataClientes.insert(0, tempClient);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'clientes/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _clientesService.registrarClientes(data);
        if (res['status'] == 200 || res['status'] == 201) {
          await cargarClientes();
          return true;
        }
        return false;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataClientes.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = ClienteModel.fromJson({
        ...dataClientes[index].toJson(),
        ...data,
      });
      dataClientes[index] = updated;
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'clientes/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _clientesService.actualizarClientes(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    // Optimistic Update
    dataClientes.removeWhere((e) => e.id == id);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'clientes/eliminar/$id',
      method: 'DELETE',
      body: {},
      apiCall: () async {
        final res = await _clientesService.eliminarClientes(id);
        return res['success'] == true;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataClientes.indexWhere((e) => e.id == id);
    if (index != -1) {
      final updated = ClienteModel.fromJson({
        ...dataClientes[index].toJson(),
        ...data,
      });
      dataClientes[index] = updated;
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'clientes/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _clientesService.deshabilitarClientes(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final clientActions =
        actions.where((a) => a.url.startsWith('clientes/')).toList();

    for (var action in clientActions) {
      bool success = false;
      if (action.url == 'clientes/registrar') {
        final res = await _clientesService.registrarClientes(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('clientes/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _clientesService.actualizarClientes(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('clientes/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _clientesService.eliminarClientes(id);
        success = res['success'] == true;
      } else if (action.url.startsWith('clientes/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res =
            await _clientesService.deshabilitarClientes(id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Client synced: ${action.id}");
        await cargarClientes(); // Refresh cache with server data
      }
    }
  }
}
