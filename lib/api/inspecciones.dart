import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'package:dio/dio.dart';

class InspeccionesService {
  final _api = ApiClient().dio;

  Future<List<dynamic>> listarInspecciones() async {
    try {
      final response = await _api.get(endpointListarInspecciones);
      return response.data is List ? response.data : [];
    } catch (e) {
      debugPrint("Error listando inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesAbiertas() async {
    try {
      final response = await _api.get(endpointListarInspeccionesAbiertas);
      return response.data is List ? response.data : [];
    } catch (e) {
      debugPrint("Error listando inspecciones abiertas: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesCerradas() async {
    try {
      final response = await _api.get(endpointListarInspeccionesCerradas);
      return response.data is List ? response.data : [];
    } catch (e) {
      debugPrint("Error listando inspecciones cerradas: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesPorCliente(String idCliente) async {
    try {
      final response =
          await _api.get('$endpointListarInspeccionesCliente/$idCliente');
      return response.data is List ? response.data : [];
    } catch (e) {
      debugPrint("Error listando inspecciones por cliente: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesResultados(String idEncuesta) async {
    try {
      final response = await _api
          .get('$endpointListarInspeccionesResultadosEncuestas/$idEncuesta');
      return response.data is List ? response.data : [];
    } catch (e) {
      debugPrint("Error listando resultados de inspecciones: $e");
      return [];
    }
  }

  Future<List<dynamic>> listarInspeccionesDatos(String id) async {
    try {
      final response =
          await _api.get('$endpointListarInspeccionesDatosEncuestas/$id');
      return response.data is List ? response.data : [];
    } catch (e) {
      debugPrint("Error listando datos de inspecciones: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraInspecciones(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarInspecciones, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando inspección: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<dynamic> obtenerInspecciones(String params) async {
    try {
      final response = await _api.get('$endpointObtenerInspecciones/$params');
      return response.data;
    } catch (e) {
      debugPrint("Error obteniendo inspección: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> actualizarInspecciones(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarInspecciones/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando inspección: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> actualizarImagenesInspecciones(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarImagenesFinales/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando imágenes de inspección: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> eliminarInspecciones(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.delete('$endpointEliminarInspecciones/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error eliminando inspección: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarInspecciones(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarInspecciones/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando inspección: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendEmail(String id) async {
    try {
      final response = await _api.get('$endpointEnviarPdf/$id');
      return {
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error enviando email: $e");
      return {'status': 500};
    }
  }

  Future<Map<String, dynamic>> sendEmail2(String id, String pdfFilePath) async {
    try {
      final formData = FormData.fromMap({
        'id': id,
        'pdf': await MultipartFile.fromFile(pdfFilePath,
            filename: 'documento.pdf'),
      });

      final response =
          await _api.post('$endpointEnviarPdf2/$id', data: formData);

      return {
        'status': response.statusCode,
        'message': response.statusCode == 200
            ? 'PDF enviado exitosamente'
            : 'Error al enviar el PDF: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint("Error enviando email(2): $e");
      return {
        'status': 500,
        'message': 'Error al enviar el PDF: $e',
      };
    }
  }

  String urlDownloadPDF(String id) {
    return '${_api.options.baseUrl}$endpointDescargarPdf/$id';
  }

  Future<Map<String, dynamic>> urlDownloadZIP(String id, String email) async {
    try {
      final response = await _api.get('$endpointEnviarZip/$id/$email');
      return {
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error enviando ZIP: $e");
      return {'status': 500};
    }
  }
}
