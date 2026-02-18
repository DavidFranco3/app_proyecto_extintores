import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class ClasificacionesService {
  final _api = ApiClient().dio;

  // Listar clasificaciones
  Future<List<dynamic>> listarClasificaciones() async {
    try {
      final response = await _api.get(endpointListarClasificaciones);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando clasificaciones: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando clasificaciones: $e");
      return [];
    }
  }

  // Registrar clasificaciones
  Future<Map<String, dynamic>> registrarClasificaciones(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarClasificaciones, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando clasificaciones: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener clasificaciones por ID
  Future<Map<String, dynamic>> obtenerClasificaciones(String id) async {
    try {
      final response = await _api.get('$endpointObtenerClasificaciones/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {'success': false, 'message': 'Error al obtener clasificación'};
      }
    } catch (e) {
      debugPrint("Error obteniendo clasificación: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Actualizar clasificación
  Future<Map<String, dynamic>> actualizarClasificaciones(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarClasificaciones/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando clasificación: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar clasificación
  Future<Map<String, dynamic>> eliminarClasificaciones(String id) async {
    try {
      final response =
          await _api.delete('$endpointEliminarClasificaciones/$id');
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error eliminando clasificación: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Deshabilitar clasificación
  Future<Map<String, dynamic>> deshabilitarClasificaciones(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointDeshabilitarClasificaciones/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando clasificación: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
