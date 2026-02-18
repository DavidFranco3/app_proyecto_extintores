import 'package:flutter/foundation.dart';
import '../../api/inspecciones.dart';
import 'base_controller.dart';

class InspeccionesController extends BaseController {
  List<Map<String, dynamic>> dataInspecciones = [];
  final _service = InspeccionesService();

  Future<void> cargarInspecciones(String clientId,
      {String cacheBox = 'inspeccionesBox'}) async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _service.listarInspeccionesPorCliente(clientId),
      cacheBox: cacheBox,
      cacheKey: 'inspecciones_$clientId',
      onDataReceived: (data) {
        dataInspecciones = _formatModel(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataInspecciones = List<Map<String, dynamic>>.from(cachedData
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => item['estado'] == "true"));
        }
      },
      formatToCache: (data) => _formatModel(data),
    );
  }

  Future<void> _saveToCache() async {
    // Note: This logic depends on the current clientId being known.
    // For simplicity, we assume the box manages the list properly.
    await updateCache('inspeccionesBox', 'inspecciones', dataInspecciones);
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
    dataInspecciones.insert(0, tempRecord);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'inspecciones/registrar',
      method: 'POST',
      body: data,
      apiCall: () async {
        final res = await _service.registraInspecciones(data);
        if (res['status'] == 200 || res['status'] == 201) {
          // Replace temp with real data or just reload
          if (data['idCliente'] != null)
            await cargarInspecciones(data['idCliente']);
          return true;
        }
        return false;
      },
    );
  }

  Future<bool> actualizar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataInspecciones.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataInspecciones[index] = {...dataInspecciones[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'inspecciones/actualizar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizarInspecciones(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> actualizarImagenes(String id, Map<String, dynamic> data) async {
    return await performOfflineAction(
      url: 'inspecciones/actualizarImagenes/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizarImagenesInspecciones(id, data);
        return res['status'] == 200;
      },
    );
  }

  Future<bool> eliminar(String id) async {
    // Optimistic Update
    dataInspecciones.removeWhere((e) => e['id'] == id);
    notifyListeners();
    await _saveToCache();

    return await performOfflineAction(
      url: 'inspecciones/eliminar/$id',
      method: 'DELETE',
      apiCall: () async {
        final res = await _service.eliminarInspecciones(id, {});
        return res['status'] == 200;
      },
    );
  }

  Future<bool> deshabilitar(String id, Map<String, dynamic> data) async {
    // Optimistic Update
    final index = dataInspecciones.indexWhere((e) => e['id'] == id);
    if (index != -1) {
      dataInspecciones[index] = {...dataInspecciones[index], ...data};
      notifyListeners();
      await _saveToCache();
    }

    return await performOfflineAction(
      url: 'inspecciones/deshabilitar/$id',
      method: 'PUT',
      body: data,
      apiCall: () async {
        final res = await _service.actualizaDeshabilitarInspecciones(id, data);
        return res['status'] == 200;
      },
    );
  }

  @override
  Future<void> syncPendingActions() async {
    final actions = await queue.getPendingActions();
    final inspActions =
        actions.where((a) => a.url.startsWith('inspecciones/')).toList();

    for (var action in inspActions) {
      bool success = false;
      String? clientId;
      if (action.url == 'inspecciones/registrar') {
        final res = await _service.registraInspecciones(action.body);
        success = res['status'] == 200 || res['status'] == 201;
        clientId = action.body['idCliente'];
      } else if (action.url.startsWith('inspecciones/actualizar/')) {
        final id = action.url.split('/').last;
        final res = await _service.actualizarInspecciones(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('inspecciones/actualizarImagenes/')) {
        final id = action.url.split('/').last;
        final res =
            await _service.actualizarImagenesInspecciones(id, action.body);
        success = res['status'] == 200;
      } else if (action.url.startsWith('inspecciones/eliminar/')) {
        final id = action.url.split('/').last;
        final res = await _service.eliminarInspecciones(id, {});
        success = res['status'] == 200;
      } else if (action.url.startsWith('inspecciones/deshabilitar/')) {
        final id = action.url.split('/').last;
        final res =
            await _service.actualizaDeshabilitarInspecciones(id, action.body);
        success = res['status'] == 200;
      }

      if (success) {
        await queue.removeAction(action.id);
        debugPrint("✅ Inspeccion synced: ${action.id}");
        if (clientId != null) await cargarInspecciones(clientId);
      }
    }
  }

  List<Map<String, dynamic>> _formatModel(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'idRama': item['cuestionario']?['idRama'],
        'idClasificacion': item['cuestionario']?['idClasificacion'],
        'idFrecuencia': item['cuestionario']?['idFrecuencia'],
        'idCuestionario': item['cuestionario']?['_id'],
        'encuesta': item['encuesta'],
        'imagenes': item?['imagenes'] ?? [],
        'imagenesCloudinary': item?['imagenesCloudinary'] ?? [],
        'imagenes_finales': item?['imagenesFinales'] ?? [],
        'imagenes_finales_cloudinary': item?['imagenesFinalesCloudinary'] ?? [],
        'comentarios': item['comentarios'],
        'preguntas': item['encuesta'],
        'descripcion': item['descripcion'],
        'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
        'cliente': item['cliente']?['nombre'] ?? 'Sin cliente',
        'puestoCliente': item['cliente']?['puesto'] ?? 'Sin puesto',
        'responsableCliente':
            item['cliente']?['responsable'] ?? 'Sin responsable',
        'estadoDom':
            item['cliente']?['direccion']?['estadoDom'] ?? 'Sin estado',
        'municipio':
            item['cliente']?['direccion']?['municipio'] ?? 'Sin municipio',
        'imagen_cliente': item['cliente']?['imagen'],
        'imagen_cliente_cloudinary': item['cliente']?['imagenCloudinary'],
        'firma_usuario': item['usuario']?['firma'],
        'firma_usuario_cloudinary': item['usuario']?['firmaCloudinary'],
        'cuestionario': item['cuestionario']?['nombre'] ?? 'Sin cuestionario',
        'usuarios': item['usuario'],
        'inspeccion_eficiencias': item['inspeccionEficiencias'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }
}
