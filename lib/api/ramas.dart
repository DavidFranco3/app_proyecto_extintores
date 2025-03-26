import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart'; // Importa el archivo donde definiste los endpoints
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints
import 'auth.dart';

final authService = AuthService();

class RamasService {
  // Listar ramas
  Future<List<dynamic>> listarRamas() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_RAMAS),
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
      print("Error al obtener las ramas: $e");
      return [];
    }
  }

  // Registrar rama
  Future<Map<String, dynamic>> registrarRamas(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_RAMAS),
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

  // Obtener rama por ID
  Future<Map<String, dynamic>> obtenerRamas(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_RAMAS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Error al obtener rama'};
    }
  }

  // Actualizar rama
  Future<Map<String, dynamic>> actualizarRamas(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_RAMAS + '/$id'),
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

  // Eliminar rama
  Future<Map<String, dynamic>> eliminarRamas(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_RAMAS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Rama eliminado'};
    } else {
      return {'success': false, 'message': 'Error al eliminar rama'};
    }
  }

  // Deshabilitar rama
  Future<Map<String, dynamic>> deshabilitarRamas(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_RAMAS + '/$id'),
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
