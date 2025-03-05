import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'endpoints.dart';
import 'auth.dart';

final authService = AuthService();

class UsuariosService {
  // Listar usuarios
  Future<List<dynamic>> listarUsuarios() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_USUARIO),
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

  // Registrar usuario
  Future<Map<String, dynamic>> registraUsuarios(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_USUARIO),
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

  // Obtener datos del usuario por ID
  Future<http.Response> obtenerUsuario(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_USUARIOS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<Map<String, dynamic>?> obtenerUsuario2(String id) async {
    final token = await authService.getTokenApi();
    try {
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_OBTENER_USUARIOS + '/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Decodificar la respuesta JSON y asignar a un Map
        return jsonDecode(
            response.body); // Esto devuelve un Map<String, dynamic>
      } else {
        print('Error: ${response.statusCode}');
        return null; // En caso de error, retorna null
      }
    } catch (e) {
      print('Error al obtener el usuario: $e');
      return null; // En caso de error, retorna null
    }
  }

  // Obtener datos del usuario por email
  Future<http.Response> obtenerUsuarioEmail(String email) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_USUARIOS_EMAIL + '/$email'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  // Actualizar usuario
  Future<Map<String, dynamic>> actualizarUsuario(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_USUARIO + '/$id'),
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

  // Eliminar usuario
  Future<Map<String, dynamic>> eliminarUsuario(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_USUARIO + '/$id'),
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

  // Deshabilitar usuario
  Future<Map<String, dynamic>> actualizaDeshabilitarUsuario(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_USUARIO + '/$id'),
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
