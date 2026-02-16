import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'endpoints.dart';
import 'auth.dart';

final authService = AuthService();

class LogsService {
  // Registra log
  Future<http.Response> registraLog(Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse('$apiHost$endpointRegistroLogs'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Para obtener todos los datos de un log
  Future<http.Response> obtenerLog(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse('$apiHost$endpointObtenerLogs/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // Para obtener el número de log actual
  Future<Map<String, dynamic>> obtenerNumeroLog() async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse('$apiHost$endpointObtenerNoLogs'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Verifica si la respuesta fue exitosa (status code 200).
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta JSON a un mapa.
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load log number');
    }
  }

  // Para listar todos los logs
  Future<List<dynamic>> listarLogs() async {
    final token = await authService.getTokenApi();
    try {
      final response = await http.get(
        Uri.parse('$apiHost$endpointListarLogs'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data; // Retornar la lista directamente
        } else {
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener los logs: $e");
      return [];
    }
  }

  // Elimina logs
  Future<http.Response> eliminaLogs(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse('$apiHost$endpointEliminarLogs/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // Modifica datos de un log
  Future<http.Response> actualizaDatosLog(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointActualizarLogs/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Para obtener la IP del usuario
  Future<String> obtenIP() async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(apiIp),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return response.body.trim(); // Eliminamos espacios en blanco
    } else {
      throw Exception('Failed to load IP');
    }
  }
}
