import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class ReporteFinalService {
  final _api = ApiClient().dio;

  // Listar reporte final
  Future<List<dynamic>> listarReporteFinal() async {
    try {
      final response = await _api.get(endpointListarReporteFinal);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando reporte final: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error al obtener los reportes: $e");
      return [];
    }
  }

  // Registrar reporte final
  Future<Map<String, dynamic>> registrarReporteFinal(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarReporteFinal, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando reporte final: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Obtener reporte final por ID
  Future<Map<String, dynamic>> obtenerReporteFinal(String id) async {
    try {
      final response = await _api.get('$endpointObtenerReporteFinal/$id');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        return {'success': false, 'message': 'Error al obtener reporte'};
      }
    } catch (e) {
      debugPrint("Error obteniendo reporte final: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Actualizar reporte final
  Future<Map<String, dynamic>> actualizarReporteFinal(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarReporteFinal/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando reporte final: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  // Eliminar reporte final
  Future<Map<String, dynamic>> eliminarReporteFinal(String id) async {
    try {
      final response = await _api.delete('$endpointEliminarReporteFinal/$id');
      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Reporte eliminado'};
      } else {
        return {'success': false, 'message': 'Error al eliminar reporte'};
      }
    } catch (e) {
      debugPrint("Error eliminando reporte final: $e");
      return {'success': false, 'message': e.toString()};
    }
  }

  // Deshabilitar reporte final
  Future<Map<String, dynamic>> deshabilitarReporteFinal(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarReporteFinal/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando reporte final: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
