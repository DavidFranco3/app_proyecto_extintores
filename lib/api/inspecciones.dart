import 'package:flutter/foundation.dart';
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
        Uri.parse('12'),
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
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesAbiertas() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('12'),
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
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesCerradas() async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('12'),
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
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesPorCliente(String idCliente) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('$apiHost$endpointListarInspeccionesCliente/$idCliente'),
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
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesResultados(String idEncuesta) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(
            '$apiHost$endpointListarInspeccionesResultadosEncuestas/$idEncuesta'),
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
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesDatos(String id) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('$apiHost$endpointListarInspeccionesDatosEncuestas/$id'),
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
          debugPrint("Error: La respuesta no es una lista.");
          return [];
        }
      } else {
        debugPrint("Error: Código de estado ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener las inspecciones: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraInspecciones(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse('12'),
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
      Uri.parse('$apiHost$endpointObtenerInspecciones/$params'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return response;
  }

  Future<Map<String, dynamic>> actualizarInspecciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointActualizarInspecciones/$id'),
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

  Future<Map<String, dynamic>> actualizarImagenesInspecciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointActualizarImagenesFinales/$id'),
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

  Future<http.Response> eliminarInspecciones(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse('$apiHost$endpointEliminarInspecciones/$id'),
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
      Uri.parse('$apiHost$endpointDeshabilitarInspecciones/$id'),
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
    final String apiUrl = '$apiHost$endpointEnviarPdf/$id';

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
    final String apiUrl = '$apiHost$endpointEnviarPdf2/$id';

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
    return '$apiHost$endpointDescargarPdf/$id';
  }

  Future<Map<String, dynamic>> urlDownloadZIP(String id, String email) async {
    final String apiUrl = '$apiHost$endpointEnviarZip/$id/$email';

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
}

