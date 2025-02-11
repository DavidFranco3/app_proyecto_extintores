import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart'; // Importa el archivo donde definiste los endpoints
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints

class ClientesService {

  // Listar clientes
  Future<Map<String, dynamic>> listarClientes() async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_LISTAR_CLIENTES),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Error al obtener clientes'};
    }
  }

  // Registrar cliente
  Future<Map<String, dynamic>> registrarClientes(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_CLIENTES),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Cliente registrado'};
    } else {
      return {'success': false, 'message': 'Error al registrar cliente'};
    }
  }

  // Obtener cliente por ID
  Future<Map<String, dynamic>> obtenerClientes(String id) async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_CLIENTES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Error al obtener cliente'};
    }
  }

  // Actualizar cliente
  Future<Map<String, dynamic>> actualizarClientes(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_CLIENTES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Cliente actualizado'};
    } else {
      return {'success': false, 'message': 'Error al actualizar cliente'};
    }
  }

  // Eliminar cliente
  Future<Map<String, dynamic>> eliminarClientes(String id) async {
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_CLIENTES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Cliente eliminado'};
    } else {
      return {'success': false, 'message': 'Error al eliminar cliente'};
    }
  }

  // Deshabilitar cliente
  Future<Map<String, dynamic>> deshabilitarClientes(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_CLIENTES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Cliente deshabilitado'};
    } else {
      return {'success': false, 'message': 'Error al deshabilitar cliente'};
    }
  }
}
