import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';
import 'package:dio/dio.dart';

class TiposExtintoresService {
  final _api = ApiClient().dio;

  // Listar tipos de extintores
  Future<List<dynamic>> listarTiposExtintores() async {
    try {
      final response = await _api.get(endpointListarTiposExtintores);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint(
            "Error listando tipos de extintores: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando tipos de extintores: $e");
      return [];
    }
  }

  // Registra tipos de extintores
  Future<Map<String, dynamic>> registraTiposExtintores(
      Map<String, dynamic> data) async {
    try {
      final response =
          await _api.post(endpointRegistrarTiposExtintores, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando tipo de extintor: $e");
      return {
        'body': e.toString(),
        'status': 500,
      };
    }
  }

  // Para obtener todos los datos de tipos de extintores
  Future<Map<String, dynamic>> obtenerTiposExtintores(String id) async {
    try {
      final response = await _api.get('$endpointObtenerTiposExtintores/$id');
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error obteniendo tipo de extintor: $e");
      return {
        'body': e.toString(),
        'status': 500,
      };
    }
  }

  // Actualizar tipos de extintores
  Future<Map<String, dynamic>> actualizarTiposExtintores(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarTiposExtintores/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando tipo de extintor: $e");
      return {
        'body': e.toString(),
        'status': 500,
      };
    }
  }

  // Eliminar tipos de extintores
  Future<Response> eliminarTiposExtintores(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.delete('$endpointEliminarTiposExtintores/$id', data: data);
      return response;
    } catch (e) {
      debugPrint("Error eliminando tipo de extintor: $e");
      rethrow;
    }
  }

  // Deshabilitar tipos de extintores
  Future<Map<String, dynamic>> actualizaDeshabilitarTiposExtintores(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await _api
          .put('$endpointDeshabilitarTiposExtintores/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando tipo de extintor: $e");
      return {
        'body': e.toString(),
        'status': 500,
      };
    }
  }
}
