import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class FrecuenciasService {
  final _api = ApiClient().dio;

  Future<List<dynamic>> listarFrecuencias() async {
    try {
      final response = await _api.get(endpointListarFrecuencias);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando frecuencias: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando frecuencias: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraFrecuencias(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarFrecuencias, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando frecuencia: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<dynamic> obtenerFrecuencias(String params) async {
    try {
      final response = await _api.get('$endpointObtenerFrecuencias/$params');
      return response.data;
    } catch (e) {
      debugPrint("Error obteniendo frecuencia: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> actualizarFrecuencias(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarFrecuencias/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando frecuencia: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> eliminarFrecuencias(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.delete('$endpointEliminarFrecuencias/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error eliminando frecuencia: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarFrecuencias(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarFrecuencias/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando frecuencia: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
