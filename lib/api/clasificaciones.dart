import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart'; // Importa el archivo donde definiste los endpoints
import 'auth.dart';
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints

final authService = AuthService();

class ClasificacionesService {
  // Listar clasificacionhes
  Future<List<dynamic>> listarClasificaciones() async {
    final token = await authService.getTokenApi();
    try {
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_CLASIFICACIONES),
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
      print("Error al obtener las clasificaciones: $e");
      return [];
    }
  }

  // Registrar clasificaciones
  Future<Map<String, dynamic>> registrarClasificaciones(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_CLASIFICACIONES),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  // Obtener clasificaciones por ID
  Future<Map<String, dynamic>> obtenerClasificaciones(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_CLASIFICACIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Error al obtener clasificación'};
    }
  }

  // Actualizar clasificación
  Future<Map<String, dynamic>> actualizarClasificaciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_CLASIFICACIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  // Eliminar clasificación
  Future<Map<String, dynamic>> eliminarClasificaciones(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_CLASIFICACIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  // Deshabilitar clasificación
  Future<Map<String, dynamic>> deshabilitarClasificaciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_CLASIFICACIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }
}
