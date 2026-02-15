import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import './endpoints.dart';
import 'auth.dart';

final authService = AuthService();

class InspeccionesProximasService {
  Future<List<dynamic>> listarInspeccionesProximas() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('12'),
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
      debugPrint("Error al obtener las inspecciones proximas: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraInspeccionesProximas(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse('12'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  Future<http.Response> obtenerInspeccionesProximas(String params) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse('$apiHost$endpointObtenerInspeccionesProximas/$params'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> actualizarInspeccionesProximas(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointActualizarInspeccionesProximas/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<http.Response> eliminarInspeccionesProximas(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse('$apiHost$endpointEliminarInspeccionesProximas/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarInspeccionesProximas(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(
          '$apiHost$endpointDeshabilitarInspeccionesProximas/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }
}



