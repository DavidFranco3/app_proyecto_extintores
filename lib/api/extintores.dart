import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import 'endpoints.dart';

class ExtintoresService {
  final _api = ApiClient().dio;

  Future<List<dynamic>> listarExtintores() async {
    try {
      final response = await _api.get(endpointListarExtintores);
      if (response.statusCode == 200) {
        return response.data is List ? response.data : [];
      } else {
        debugPrint("Error listando extintores: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error listando extintores: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> registraExtintores(
      Map<String, dynamic> data) async {
    try {
      final response = await _api.post(endpointRegistrarExtintores, data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error registrando extintor: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<dynamic> obtenerExtintores(String params) async {
    try {
      final response = await _api.get('$endpointObtenerExtintores/$params');
      return response.data;
    } catch (e) {
      debugPrint("Error obteniendo extintor: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> actualizarExtintores(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointActualizarExtintores/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error actualizando extintor: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> eliminarExtintores(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.delete('$endpointEliminarExtintores/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error eliminando extintor: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> actualizaDeshabilitarExtintores(
      String id, Map<String, dynamic> data) async {
    try {
      final response =
          await _api.put('$endpointDeshabilitarExtintores/$id', data: data);
      return {
        'body': response.data,
        'status': response.statusCode,
      };
    } catch (e) {
      debugPrint("Error deshabilitando extintor: $e");
      return {'status': 500, 'message': e.toString()};
    }
  }
}
