import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import './endpoints.dart';

class InspeccionesService {
  Future<List<dynamic>> listarInspecciones() async {
    try {
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_INSPECCIONES),
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
      print("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraInspecciones(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_INSPECCIONES),
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

  Future<http.Response> obtenerInspecciones(String params) async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_INSPECCIONES + '/$params'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  Future<http.Response> actualizarInspecciones(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_INSPECCIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<http.Response> eliminarInspecciones(
      String id, Map<String, dynamic> data) async {
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_INSPECCIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarInspecciones(
      String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_INSPECCIONES + '/$id'),
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

  Future<Map<String, dynamic>> sendEmail(String id) async {
  final String apiUrl = API_HOST + ENDPOINT_ENVIAR_PDF + '/$id';

  final response = await http.get(
    Uri.parse(apiUrl),
    headers: {
      'Content-Type': 'application/json',
    },
  );

  return {
    'status': response.statusCode, // Retorna la respuesta del servidor
  };
}

  String urlDownloadPDF(String id) {
    return API_HOST + ENDPOINT_DESCARGAR_PDF + '/$id';
  }
}
