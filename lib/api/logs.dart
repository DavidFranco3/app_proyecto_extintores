import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'package:dio/dio.dart';
import '../utils/constants.dart';

class LogsService {
  final _api = ApiClient().dio;

  // Registra log
  Future<Response> registraLog(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointRegistroLogs, data: data);
      return response;
    } catch (e) {
      debugPrint("Error registrando log: $e");
      rethrow;
    }
  }

  // Para obtener todos los datos de un log
  Future<Response> obtenerLog(String id) async {
    try {
      final response = await _api.get('$endpointObtenerLogs/$id');
      return response;
    } catch (e) {
      debugPrint("Error obteniendo log: $e");
      rethrow;
    }
  }

  // Para obtener el número de log actual
  Future<Map<String, dynamic>> obtenerNumeroLog() async {
    try {
      final response = await _api.get(endpointObtenerNoLogs);
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load log number');
      }
    } catch (e) {
      debugPrint("Error obteniendo número de log: $e");
      rethrow;
    }
  }

  // Para listar todos los logs
  Future<List<dynamic>> listarLogs() async {
    try {
      final response = await _api.get(endpointListarLogs);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando logs: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al listar logs: $e");
      return [];
    }
  }

  // Elimina logs
  Future<Response> eliminaLogs(String id) async {
    try {
      final response = await _api.delete('$endpointEliminarLogs/$id');
      return response;
    } catch (e) {
      debugPrint("Error eliminando log: $e");
      rethrow;
    }
  }

  // Modifica datos de un log
  Future<Response> actualizaDatosLog(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarLogs/$id', data: data);
      return response;
    } catch (e) {
      debugPrint("Error actualizando log: $e");
      rethrow;
    }
  }

  // Para obtener la IP del usuario
  Future<String> obtenIP() async {
    try {
      // Assuming apiIp is a standalone URL or an endpoint
      final response = await _api.get(apiIp);
      if (response.statusCode == 200) {
        return response.data.toString().trim();
      } else {
        throw Exception('Failed to load IP');
      }
    } catch (e) {
      debugPrint("Error obteniendo IP: $e");
      throw Exception('Failed to load IP');
    }
  }
}
