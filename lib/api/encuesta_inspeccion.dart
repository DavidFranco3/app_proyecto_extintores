import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class EncuestaInspeccionService {
  final _api = ApiClient().dio;

  // Listar encuesta de Inspección
  Future<List<dynamic>> listarEncuestaInspeccion() async {
    try {
      final response = await _api.get(endpointListarEncuestaInspeccion);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando encuestas: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando encuestas: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarEncuestaInspeccionPorRama(
      String idRama, String idFrecuencia, String idClasificacion) async {
    try {
      final response = await _api.get(
          '$endpointListarEncuestaInspeccionRama/$idRama/$idFrecuencia/$idClasificacion');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando encuestas por rama: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando encuestas por rama: $e");
      return [];
    }
  }

  // Registrar encuesta de Inspección
  Future<Map<String, dynamic>> registraEncuestaInspeccion(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarEncuestaInspeccion, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando encuesta: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener encuesta de Inspección por ID
  Future<Map<String, dynamic>> obtenerEncuestaInspeccion(String id) async {
    try {
      final response = await _api.get('$endpointObtenerEncuestaInspeccion/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load encuesta de Inspección');
      }
    } catch (e) {
      debugPrint("Error obteniendo encuesta: $e");
      rethrow;
    }
  }

  // Actualizar encuesta de Inspección
  Future<Map<String, dynamic>> actualizarEncuestaInspeccion(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointActualizarEncuestaInspeccion/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando encuesta: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar encuesta de Inspección
  Future<Map<String, dynamic>> eliminarEncuestaInspeccion(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .delete('$endpointEliminarEncuestaInspeccion/$id', data: data);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to delete encuesta de Inspección');
      }
    } catch (e) {
      debugPrint("Error eliminando encuesta: $e");
      rethrow;
    }
  }

  // Deshabilitar encuesta de Inspección
  Future<Map<String, dynamic>> deshabilitarEncuestaInspeccion(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointDeshabilitarEncuestaInspeccion/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando encuesta: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
