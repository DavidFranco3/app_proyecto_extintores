import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'endpoints.dart';

class LogsService {
  // Registra log
  Future<http.Response> registraLog(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRO_LOGS),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Para obtener todos los datos de un log
  Future<http.Response> obtenerLog(String id) async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_LOGS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Para obtener el número de log actual
  Future<Map<String, dynamic>> obtenerNumeroLog() async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_NO_LOGS),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    // Verifica si la respuesta fue exitosa (status code 200).
    if (response.statusCode == 200) {
      // Decodifica el cuerpo de la respuesta JSON a un mapa.
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load log number');
    }
  }

  // Para listar todos los logs
  Future<List<dynamic>> listarLogs() async {
    try {
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_LOGS),
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
      print("Error al obtener las clasificaciones: $e");
      return [];
    }
  }

  // Elimina logs
  Future<http.Response> eliminaLogs(String id) async {
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_LOGS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Modifica datos de un log
  Future<http.Response> actualizaDatosLog(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_LOGS + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Para obtener la IP del usuario
  Future<String> obtenIP() async {
    final response = await http.get(
      Uri.parse(API_IP),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return response.body.trim(); // Eliminamos espacios en blanco
    } else {
      throw Exception('Failed to load IP');
    }
  }
}
