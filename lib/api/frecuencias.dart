import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'endpoints.dart';
import 'auth.dart';

final authService = AuthService();

class FrecuenciasService {
  Future<List<dynamic>> listarFrecuencias() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_FRECUENCIAS),
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
          print("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        print("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error al obtener las frecuencias: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraFrecuencias(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_FRECUENCIAS),
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

  Future<http.Response> obtenerFrecuencias(String params) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_FRECUENCIAS + '/$params'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizarFrecuencias(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_FRECUENCIAS + '/$id'),
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

  Future<http.Response> eliminarFrecuencias(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_FRECUENCIAS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarFrecuencias(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_FRECUENCIAS + '/$id'),
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
