import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart'; // Importa el archivo donde definiste los endpoints
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints
import 'auth.dart';

final authService = AuthService();

class EncuestaInspeccionClienteService {
// Listar encuesta de Inspección
  Future<List<dynamic>> listarEncuestaInspeccionCliente() async {
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

  Future<List<dynamic>> listarEncuestaInspeccionClientePorRama(
      String idRama, String idFrecuencia, String idClasificacion) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('$apiHost$endpointListarEncuestaInspeccionRamaCliente/$idRama/$idFrecuencia/$idClasificacion'),
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

  Future<List<dynamic>> listarEncuestaInspeccionClientePorRamaPorCliente(
      String idRama,
      String idFrecuencia,
      String idClasificacion,
      String idCliente) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse('$apiHost$endpointListarEncuestaInspeccionRamaPorCliente/$idRama/$idFrecuencia/$idClasificacion/$idCliente'),
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

// Registrar encuesta de Inspección
  Future<Map<String, dynamic>> registraEncuestaInspeccionCliente(
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

// Obtener encuesta de Inspección por ID
  Future<Map<String, dynamic>> obtenerEncuestaInspeccionCliente(
      String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse(
          '$apiHost$endpointObtenerEncuestaInspeccionCliente/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load encuesta de Inspección');
    }
  }

  Future<List<dynamic>> obtenerEncuestaInspeccionClienteEncuestas(String idCliente) async {
  final token = await authService.getTokenApi();
  final response = await http.get(
    Uri.parse(
        '$apiHost$endpointObtenerEncuestaInspeccionClienteEncuestas/$idCliente'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return List<dynamic>.from(json.decode(response.body));
  } else {
    throw Exception('Failed to load encuesta de Inspección');
  }
}


// Actualizar encuesta de Inspección
  Future<Map<String, dynamic>> actualizarEncuestaInspeccionCliente(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse(
          '$apiHost$endpointActualizarEncuestaInspeccionCliente/$id'),
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

// Eliminar encuesta de Inspección
  Future<Map<String, dynamic>> eliminarEncuestaInspeccionCliente(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse(
          '$apiHost$endpointEliminarEncuestaInspeccionCliente/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to delete encuesta de Inspección');
    }
  }

// Deshabilitar encuesta de Inspección
  Future<Map<String, dynamic>> deshabilitarEncuestaInspeccionCliente(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointDeshabilitarEncuestaInspeccionCliente/$id'),
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
}



