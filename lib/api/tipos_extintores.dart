import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import './endpoints.dart';
import 'auth.dart';

final authService = AuthService();

class TiposExtintoresService {
  // Listar tipos de extintores
  Future<List<dynamic>> listarTiposExtintores() async {
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
      debugPrint("Error al obtener los tipos de extintores: $e");
      return [];
    }
  }

  // Registra tipos de extintores
  Future<Map<String, dynamic>> registraTiposExtintores(
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

  // Para obtener todos los datos de tipos de extintores
  Future<Map<String, dynamic>> obtenerTiposExtintores(String id) async {
    final token = await authService.getTokenApi();
    final response = await http.get(
      Uri.parse('$apiHost$endpointObtenerTiposExtintores/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }

  // Actualizar tipos de extintores
  Future<Map<String, dynamic>> actualizarTiposExtintores(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointActualizarTiposExtintores/$id'),
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

  // Eliminar tipos de extintores
  Future<http.Response> eliminarTiposExtintores(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.delete(
      Uri.parse('$apiHost$endpointEliminarTiposExtintores/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Deshabilitar tipos de extintores
  Future<Map<String, dynamic>> actualizaDeshabilitarTiposExtintores(
      String id, Map<String, dynamic> data) async {
    final token = await authService.getTokenApi();
    final response = await http.put(
      Uri.parse('$apiHost$endpointDeshabilitarTiposExtintores/$id'),
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



