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
        Uri.parse(API_HOST + ENDPOINT_LISTAR_ENCUESTA_INSPECCION_CLIENTE),
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

  Future<List<dynamic>> listarEncuestaInspeccionClientePorRama(
      String idRama, String idFrecuencia, String idClasificacion) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST +
            ENDPOINT_LISTAR_ENCUESTA_INSPECCION_RAMA_CLIENTE +
            '/$idRama/$idFrecuencia/$idClasificacion'),
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

  Future<List<dynamic>> listarEncuestaInspeccionClientePorRamaPorCliente(
      String idRama,
      String idFrecuencia,
      String idClasificacion,
      String idCliente) async {
    try {
      final token = await authService.getTokenApi();
      final response = await http.get(
        Uri.parse(API_HOST +
            ENDPOINT_LISTAR_ENCUESTA_INSPECCION_RAMA_POR_CLIENTE +
            '/$idRama/$idFrecuencia/$idClasificacion/$idCliente'),
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

// Registrar encuesta de Inspección
  Future<Map<String, dynamic>> registraEncuestaInspeccionCliente(
      Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_ENCUESTA_INSPECCION_CLIENTE),
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
          API_HOST + ENDPOINT_OBTENER_ENCUESTA_INSPECCION_CLIENTE + '/$id'),
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
        API_HOST + ENDPOINT_OBTENER_ENCUESTA_INSPECCION_CLIENTE_ENCUESTAS + '/$idCliente'),
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
          API_HOST + ENDPOINT_ACTUALIZAR_ENCUESTA_INSPECCION_CLIENTE + '/$id'),
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
          API_HOST + ENDPOINT_ELIMINAR_ENCUESTA_INSPECCION_CLIENTE + '/$id'),
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
      Uri.parse(API_HOST +
          ENDPOINT_DESHABILITAR_ENCUESTA_INSPECCION_CLIENTE +
          '/$id'),
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
