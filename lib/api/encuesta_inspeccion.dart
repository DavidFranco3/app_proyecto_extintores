import 'dart:convert';
import 'package:http/http.dart' as http;
import 'endpoints.dart'; // Importa el archivo donde definiste los endpoints
import '../utils/constants.dart'; // Importa el archivo donde definiste los endpoints
// Listar encuesta de Inspección
Future<List<dynamic>> listarEncuestaInspeccion() async {
  final response = await http.get(
    Uri.parse(API_HOST + ENDPOINT_LISTAR_ENCUESTA_INSPECCION),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    // Retorna los datos como una lista
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load encuesta de Inspección');
  }
}

// Registrar encuesta de Inspección
Future<Map<String, dynamic>> registraEncuestaInspeccion(Map<String, dynamic> data) async {
  final response = await http.post(
    Uri.parse(API_HOST + ENDPOINT_REGISTRAR_ENCUESTA_INSPECCION),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: json.encode(data),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to register encuesta de Inspección');
  }
}

// Obtener encuesta de Inspección por ID
Future<Map<String, dynamic>> obtenerEncuestaInspeccion(String id) async {
  final response = await http.get(
    Uri.parse(API_HOST + ENDPOINT_OBTENER_ENCUESTA_INSPECCION + '/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to load encuesta de Inspección');
  }
}

// Actualizar encuesta de Inspección
Future<Map<String, dynamic>> actualizarEncuestaInspeccion(String id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_ENCUESTA_INSPECCION + '/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: json.encode(data),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to update encuesta de Inspección');
  }
}

// Eliminar encuesta de Inspección
Future<Map<String, dynamic>> eliminarEncuestaInspeccion(String id, Map<String, dynamic> data) async {
  final response = await http.delete(
    Uri.parse(API_HOST + ENDPOINT_ELIMINAR_ENCUESTA_INSPECCION + '/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
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
Future<Map<String, dynamic>> deshabilitarEncuestaInspeccion(String id, Map<String, dynamic> data) async {
  final response = await http.put(
    Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_ENCUESTA_INSPECCION + '/$id'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: json.encode(data),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to disable encuesta de Inspección');
  }
}
