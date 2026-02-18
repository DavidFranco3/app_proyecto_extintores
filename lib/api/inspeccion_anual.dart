import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'package:dio/dio.dart';

class InspeccionAnualService {
  final _api = ApiClient().dio;

  // Listar inspeccion anual
  Future<List<dynamic>> listarInspeccionAnual() async {
    try {
      final response = await _api.get(endpointListarInspeccionAnual);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint(
            "Error listando inspecciones anuales: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando inspecciones anuales: $e");
      return [];
    }
  }

  // Listar inspeccion anual por ID
  Future<List<dynamic>> listarInspeccionAnualId(String id) async {
    try {
      final response = await _api.get('$endpointListarInspeccionAnualId/$id');
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint(
            "Error listando inspección anual id: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando inspección anual id: $e");
      return [];
    }
  }

  // Registrar inspección anual
  Future<Map<String, dynamic>> registrarInspeccionAnual(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarInspeccionAnual, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando inspección anual: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener inspección anual por ID
  Future<Map<String, dynamic>> obtenerInspeccionAnual(String id) async {
    try {
      final response = await _api.get('$endpointObtenerInspeccionAnual/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {
          'success': false,
          'message': 'Error al obtener inspección anual'
        };
      }
    } catch (e) {
      debugPrint("Error obteniendo inspección anual: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Actualizar inspección anual
  Future<Map<String, dynamic>> actualizarInspeccionAnual(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarInspeccionAnual/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando inspección anual: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar inspección anual
  Future<Map<String, dynamic>> eliminarInspeccionAnual(String id) async {
    try {
      final response =
          await _api.delete('$endpointEliminarInspeccionAnual/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Inspección anual eliminada'};
      } else {
        return {
          'success': false,
          'message': 'Error al eliminar inspección anual'
        };
      }
    } catch (e) {
      debugPrint("Error eliminando inspección anual: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Deshabilitar inspección anual
  Future<Map<String, dynamic>> deshabilitarInspeccionAnual(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointDeshabilitarInspeccionAnual/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando inspección anual: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendEmail(String id, String pdfFilePath) async {
    try {
      final formData = FormData.fromMap({
        'id': id,
        'pdf': await MultipartFile.fromFile(pdfFilePath,
            filename: 'documento.pdf'),
      });

      final response = await _api.post('$endpointEnviarPdfInspeccionAnual/$id',
          data: formData);

      return {
        'status': response.statusCode,
        'message': response.statusCode == 200
            ? 'PDF enviado exitosamente'
            : 'Error al enviar el PDF: ${response.statusCode}',
      };
    } catch (e) {
      debugPrint("Error enviando email inspección anual: $e");
      return {
        'status': 500,
        'message': 'Error al enviar el PDF: $e',
      };
    }
  }
}
