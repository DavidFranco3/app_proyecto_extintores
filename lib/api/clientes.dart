import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'models/cliente_model.dart';

class ClientesService {
  final _api = ApiClient().dio;

  // Listar clientes
  Future<List<ClienteModel>> listarClientes() async {
    try {
      final response = await _api.get(endpointListarClientes);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ClienteModel.fromJson(json)).toList();
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener los clientes: $e");
      return [];
    }
  }

  // Registrar cliente
  Future<Map<String, dynamic>> registrarClientes(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointRegistrarClientes, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error al registrar cliente: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener cliente por ID
  Future<Map<String, dynamic>> obtenerClientes(String id) async {
    try {
      final response = await _api.get('$endpointObtenerClientes/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {'success': false, 'message': 'Error al obtener cliente'};
      }
    } catch (e) {
      debugPrint("Error al obtener cliente: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Actualizar cliente
  Future<Map<String, dynamic>> actualizarClientes(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarClientes/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error al actualizar cliente: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar cliente
  Future<Map<String, dynamic>> eliminarClientes(String id) async {
    try {
      final response = await _api.delete('$endpointEliminarClientes/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Cliente eliminado'};
      } else {
        return {'success': false, 'message': 'Error al eliminar cliente'};
      }
    } catch (e) {
      debugPrint("Error al eliminar cliente: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Deshabilitar cliente
  Future<Map<String, dynamic>> deshabilitarClientes(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarClientes/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error al deshabilitar cliente: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
