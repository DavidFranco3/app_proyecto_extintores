import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class UsuariosService {
  final _api = ApiClient().dio;

  // Listar usuarios
  Future<List<dynamic>> listarUsuarios() async {
    try {
      final response = await _api.get(endpointListarUsuario);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando usuarios: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando usuarios: $e");
      return [];
    }
  }

  // Registrar usuario
  Future<Map<String, dynamic>> registraUsuarios(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointRegistrarUsuario, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando usuario: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener usuario por ID (devuelve Response para compatibilidad si es necesario o simplificado)
  Future<dynamic> obtenerUsuario(String id) async {
    try {
      final response = await _api.get('$endpointObtenerUsuarios/$id');
      return response.data;
    } catch (e) {
      debugPrint("Error obteniendo usuario: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuario2(String id) async {
    try {
      final response = await _api.get('$endpointObtenerUsuarios/$id');
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint("Error obteniendo usuario2: $e");
      return null;
    }
  }

  // Obtener usuario por email
  Future<dynamic> obtenerUsuarioEmail(String email) async {
    try {
      final response = await _api.get('$endpointObtenerUsuariosEmail/$email');
      return response.data;
    } catch (e) {
      debugPrint("Error obteniendo usuario por email: $e");
      return null;
    }
  }

  // Actualizar usuario
  Future<Map<String, dynamic>> actualizarUsuario(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarUsuario/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando usuario: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar usuario
  Future<Map<String, dynamic>> eliminarUsuario(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.delete('$endpointEliminarUsuario/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error eliminando usuario: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Deshabilitar usuario
  Future<Map<String, dynamic>> actualizaDeshabilitarUsuario(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarUsuario/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando usuario: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
