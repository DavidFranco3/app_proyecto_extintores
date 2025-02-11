import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'endpoints.dart';

class UsuarioService {
  // Listar usuarios
  Future<http.Response> listarUsuarios() async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_LISTAR_USUARIO),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Registrar usuario
  Future<http.Response> registraUsuarios(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_USUARIO),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Obtener datos del usuario por ID
  Future<http.Response> obtenerUsuario(String id) async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_USUARIOS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<Map<String, dynamic>?> obtenerUsuario2(String id) async {
  try {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_USUARIOS + '/$id'),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Decodificar la respuesta JSON y asignar a un Map
      return jsonDecode(response.body); // Esto devuelve un Map<String, dynamic>
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
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_USUARIOS_EMAIL + '/$email'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Actualizar usuario
  Future<http.Response> actualizarUsuario(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_USUARIO + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Eliminar usuario
  Future<http.Response> eliminarUsuario(String id, Map<String, dynamic> data) async {
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_USUARIO + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Deshabilitar usuario
  Future<http.Response> actualizaDeshabilitarUsuario(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_USUARIO + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }
}
