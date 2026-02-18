import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'package:dio/dio.dart';

class TokensService {
  final _api = ApiClient().dio;

  Future<List<dynamic>> listarTokens() async {
    try {
      final response = await _api.get(endpointListarTokens);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando tokens: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las tokens: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraTokens(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointRegistrarTokens, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando token: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Response> obtenerTokens(String params) async {
    try {
      final response = await _api.get('$endpointObtenerTokens/$params');
      return response;
    } catch (e) {
      debugPrint("Error obteniendo token: $e");
      rethrow;
    }
  }

  Future<Map<String, dynamic>> actualizarTokens(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarTokens/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando token: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> eliminarTokens(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.delete('$endpointEliminarTokens/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error eliminando token: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarTokens(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarTokens/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando token: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
