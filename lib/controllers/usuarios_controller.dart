import 'package:flutter/foundation.dart';
import '../../api/usuarios.dart';
import 'base_controller.dart';

class UsuariosController extends BaseController {
  List<Map<String, dynamic>> dataUsuarios = [];
  final _service = UsuariosService();

  Future<void> cargarUsuarios() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarUsuarios(),
      cacheBox: 'usuariosBox',
      cacheKey: 'usuarios',
      onDataReceived: (data) {
        dataUsuarios = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataUsuarios = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) =>
                  item['estado'] == "true" || item['estado'] == null));
        }
      },
      formatToCache: (data) => _formatModel(data),
    );
  }

  Future<void> _saveToCache() async {
    await updateCache('usuariosBox', 'usuarios', dataUsuarios);
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
    dataUsuarios.insert(0, tempRecord);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'usuarios/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _service.registraUsuarios(data);
        if (res['status'] == 200 || res['status'] == 201) {
          await cargarUsuarios();
          return true;
        }
        return false;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataUsuarios.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataUsuarios[index] = {...dataUsuarios[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'usuarios/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizarUsuario(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    // Optimistic Update
    dataUsuarios.removeWhere((e) => e['id'] == id);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'usuarios/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res = await _service.eliminarUsuario(id, {});
        return res['status'] == 200;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataUsuarios.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataUsuarios[index] = {...dataUsuarios[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'usuarios/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizaDeshabilitarUsuario(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final userActions =
        actions.where((a) => a.url.startsWith('usuarios/')).toList();

    for (var action in userActions) {
      bool success = false;
      if (action.url == 'usuarios/registrar') {
        final res = await _service.registraUsuarios(action.body);
        success = res['status'] == 200 || res['status'] == 201;
      } else if (action.url.startsWith('usuarios/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _service.actualizarUsuario(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('usuarios/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _service.eliminarUsuario(id, {});
        success = res['status'] == 200;
      } else if (action.url.startsWith('usuarios/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res =
            await _service.actualizaDeshabilitarUsuario(id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Usuario synced: ${action.id}");
        await cargarUsuarios(); // Refresh with server data
      }
    }
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'email': item['email'],
        'telefono': item['telefono'],
        'tipo': item['tipo'],
        'estado': item['estado'] ?? "true",
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
