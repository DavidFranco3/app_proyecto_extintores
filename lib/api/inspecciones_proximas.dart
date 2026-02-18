import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'package:dio/dio.dart';

class InspeccionesProximasService {
  final _api = ApiClient().dio;

  Future<List<dynamic>> listarInspeccionesProximas() async {
    try {
      final response = await _api.get(endpointListarInspeccionesProximas);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint(
            "Error listando inspecciones proximas: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones proximas: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraInspeccionesProximas(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarInspeccionesProximas, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando inspección proxima: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Response> obtenerInspeccionesProximas(String params) async {
    try {
      final response =
          await _api.get('$endpointObtenerInspeccionesProximas/$params');
      return response;
    } catch (e) {
      debugPrint("Error obteniendo inspección proxima: $e");
      rethrow;
    }
  }

  Future<Response> actualizarInspeccionesProximas(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointActualizarInspeccionesProximas/$id', data: data);
      return response;
    } catch (e) {
      debugPrint("Error actualizando inspección proxima: $e");
      rethrow;
    }
  }

  Future<Response> eliminarInspeccionesProximas(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .delete('$endpointEliminarInspeccionesProximas/$id', data: data);
      return response;
    } catch (e) {
      debugPrint("Error eliminando inspección proxima: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarInspeccionesProximas(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointDeshabilitarInspeccionesProximas/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando inspección proxima: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
