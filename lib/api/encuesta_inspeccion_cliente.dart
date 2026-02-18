import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class EncuestaInspeccionClienteService {
  final _api = ApiClient().dio;

  // Listar encuesta de Inspección
  Future<List<dynamic>> listarEncuestaInspeccionCliente() async {
    try {
      final response = await _api.get(endpointListarEncuestaInspeccionCliente);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando encuestas cliente: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando encuestas cliente: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarEncuestaInspeccionClientePorRama(
      String idRama, String idFrecuencia, String idClasificacion) async {
    try {
      final response = await _api.get(
          '$endpointListarEncuestaInspeccionRamaCliente/$idRama/$idFrecuencia/$idClasificacion');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint(
            "Error listando encuestas cliente por rama: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando encuestas cliente por rama: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarEncuestaInspeccionClientePorRamaPorCliente(
      String idRama,
      String idFrecuencia,
      String idClasificacion,
      String idCliente) async {
    try {
      final response = await _api.get(
          '$endpointListarEncuestaInspeccionRamaPorCliente/$idRama/$idFrecuencia/$idClasificacion/$idCliente');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint(
            "Error listando encuestas cliente por rama por cliente: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando encuestas cliente por rama por cliente: $e");
      return [];
    }
  }

  // Registrar encuesta de Inspección
  Future<Map<String, dynamic>> registraEncuestaInspeccionCliente(
      Map<String, dynamic> data) async {
    try {
      final response = await _api
          .post(endpointRegistrarEncuestaInspeccionCliente, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando encuesta cliente: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener encuesta de Inspección por ID
  Future<Map<String, dynamic>> obtenerEncuestaInspeccionCliente(
      String id) async {
    try {
      final response =
          await _api.get('$endpointObtenerEncuestaInspeccionCliente/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load encuesta de Inspección');
      }
    } catch (e) {
      debugPrint("Error obteniendo encuesta cliente: $e");
      rethrow;
    }
  }

  Future<List<dynamic>> obtenerEncuestaInspeccionClienteEncuestas(
      String idCliente) async {
    try {
      final response = await _api
          .get('$endpointObtenerEncuestaInspeccionClienteEncuestas/$idCliente');
      if (response.statusCode == 200) {
        return List<dynamic>.from(response.data);
      } else {
        throw Exception('Failed to load encuesta de Inspección');
      }
    } catch (e) {
      debugPrint("Error obteniendo encuestas del cliente: $e");
      rethrow;
    }
  }

  // Actualizar encuesta de Inspección
  Future<Map<String, dynamic>> actualizarEncuestaInspeccionCliente(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointActualizarEncuestaInspeccionCliente/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando encuesta cliente: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar encuesta de Inspección
  Future<Map<String, dynamic>> eliminarEncuestaInspeccionCliente(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .delete('$endpointEliminarEncuestaInspeccionCliente/$id', data: data);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to delete encuesta de Inspección');
      }
    } catch (e) {
      debugPrint("Error eliminando encuesta cliente: $e");
      rethrow;
    }
  }

  // Deshabilitar encuesta de Inspección
  Future<Map<String, dynamic>> deshabilitarEncuestaInspeccionCliente(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api.put(
          '$endpointDeshabilitarEncuestaInspeccionCliente/$id',
          data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando encuesta cliente: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
