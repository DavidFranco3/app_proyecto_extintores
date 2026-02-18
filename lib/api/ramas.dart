import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class RamasService {
  final _api = ApiClient().dio;

  // Listar ramas
  Future<List<dynamic>> listarRamas() async {
    try {
      final response = await _api.get(endpointListarRamas);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando ramas: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando ramas: $e");
      return [];
    }
  }

  // Registrar rama
  Future<Map<String, dynamic>> registrarRamas(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointRegistrarRamas, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando rama: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener rama por ID
  Future<Map<String, dynamic>> obtenerRamas(String id) async {
    try {
      final response = await _api.get('$endpointObtenerRamas/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {'success': false, 'message': 'Error al obtener rama'};
      }
    } catch (e) {
      debugPrint("Error obteniendo rama: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Actualizar rama
  Future<Map<String, dynamic>> actualizarRamas(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarRamas/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando rama: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar rama
  Future<Map<String, dynamic>> eliminarRamas(String id) async {
    try {
      final response = await _api.delete('$endpointEliminarRamas/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Rama eliminada'};
      } else {
        return {'success': false, 'message': 'Error al eliminar rama'};
      }
    } catch (e) {
      debugPrint("Error eliminando rama: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Deshabilitar rama
  Future<Map<String, dynamic>> deshabilitarRamas(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarRamas/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando rama: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
