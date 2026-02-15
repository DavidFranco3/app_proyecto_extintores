import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart'; // Importa el archivo donde definiste los endpoints
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints
import 'auth.dart';
import 'dart:io';

final authService = AuthService();

class InspeccionAnualService {
  // Listar inspeccion anual
  Future<List<dynamic>> listarInspeccionAnual() async {
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
      debugPrint("Error al obtener las inspecciones anuales: $e");
      return [];
    }
  }

  // Listar inspeccion anual
  Future<List<dynamic>> listarInspeccionAnualId(String id) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('$apiHost$endpointListarInspeccionAnualId/$id'),
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
      debugPrint("Error al obtener las inspeccion anual: $e");
      return [];
    }
  }

  // Registrar cliente
  Future<Map<String, dynamic>> registrarInspeccionAnual(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse('12'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  // Obtener cliente por ID
  Future<Map<String, dynamic>> obtenerInspeccionAnual(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse('$apiHost$endpointObtenerInspeccionAnual/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return {'success': false, 'message': 'Error al obtener cliente'};
    }
  }

  // Actualizar cliente
  Future<Map<String, dynamic>> actualizarInspeccionAnual(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointActualizarInspeccionAnual/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  // Eliminar cliente
  Future<Map<String, dynamic>> eliminarInspeccionAnual(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse('$apiHost$endpointEliminarInspeccionAnual/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return {'success': true, 'message': 'Cliente eliminado'};
    } else {
      return {'success': false, 'message': 'Error al eliminar cliente'};
    }
  }

  // Deshabilitar cliente
  Future<Map<String, dynamic>> deshabilitarInspeccionAnual(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointDeshabilitarInspeccionAnual/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  Future<Map<String, dynamic>> sendEmail(String id, String pdfFilePath) async {
    final token = await authService.getTokenApi();
    final String apiUrl = '$apiHost$endpointEnviarPdfInspeccionAnual/$id';

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
}

