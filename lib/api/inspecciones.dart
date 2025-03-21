import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import './endpoints.dart';
import 'dart:io';
import 'auth.dart';

final authService = AuthService();

class InspeccionesService {
  Future<List<dynamic>> listarInspecciones() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST + ENDPOINT_LISTAR_INSPECCIONES),
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
      print("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesResultados(idEncuesta) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST +
            ENDPOINT_LISTAR_INSPECCIONES_RESULTADOS_ENCUESTAS +
            '/$idEncuesta'),
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
      print("Error al obtener las inspecciones: $e");
      return [];
    }
  }

    Future<List<dynamic>> listarInspeccionesDatos(id) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST +
            ENDPOINT_LISTAR_INSPECCIONES_DATOS_ENCUESTAS +
            '/$id'),
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
      print("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraInspecciones(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_INSPECCIONES),
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

  Future<http.Response> obtenerInspecciones(String params) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_INSPECCIONES + '/$params'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<http.Response> actualizarInspecciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_INSPECCIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<http.Response> eliminarInspecciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_INSPECCIONES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarInspecciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_INSPECCIONES + '/$id'),
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

  Future<Map<String, dynamic>> sendEmail(String id) async {
    final token = await authService.getTokenApi();
    final String apiUrl = API_HOST + ENDPOINT_ENVIAR_PDF + '/$id';

    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return {
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

Future<Map<String, dynamic>> sendEmail2(String id, String pdfFilePath) async {
    final token = await authService.getTokenApi();
    final String apiUrl = API_HOST + ENDPOINT_ENVIAR_PDF2 + '/$id';

    try {
      // Leer el archivo PDF como bytes desde el sistema de archivos
      final pdfFile = File(pdfFilePath); // Ruta donde se guarda el archivo PDF
      final bytes = await pdfFile.readAsBytes(); // Leemos el archivo como bytes

      // Crear la solicitud POST con el archivo y el ID
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl))
        ..headers.addAll({
          'Content-Type': 'multipart/form-data',
          'Authorization': 'Bearer $token', // Añadir el token en el header
        })
        // Agregar el archivo PDF
        ..files.add(http.MultipartFile.fromBytes('pdf', bytes,
            filename: 'documento.pdf'))
        // Agregar el ID como un campo del formulario
        ..fields['id'] = id;

      // Enviar la solicitud
      final response = await request.send();

      if (response.statusCode == 200) {
        return {
          'status': response.statusCode,
          'message': 'PDF enviado exitosamente',
        };
      } else {
        return {
          'status': response.statusCode,
          'message': 'Error al enviar el PDF: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'status': 500, // Error interno si ocurre alguna excepción
        'message': 'Error al enviar el PDF: $e',
      };
    }
  }

  String urlDownloadPDF(String id) {
    return API_HOST + ENDPOINT_DESCARGAR_PDF + '/$id';
  }
}
