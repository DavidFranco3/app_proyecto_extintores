import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'endpoints.dart';

class TokensService {
  Future<List<dynamic>> listarTokens() async {
    try {
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_TOKENS),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
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
      print("Error al obtener las tokens: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraTokens(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_TOKENS),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  Future<http.Response> obtenerTokens(String params) async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_TOKENS + '/$params'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizarTokens(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_TOKENS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  Future<Map<String, dynamic>> eliminarTokens(
      String id, Map<String, dynamic> data) async {
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_TOKENS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarTokens(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_TOKENS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }
}
