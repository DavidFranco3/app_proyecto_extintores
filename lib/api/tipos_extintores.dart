import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import './endpoints.dart';

class TiposExtintoresService {
  // Listar tipos de extintores
  Future<http.Response> listarTiposExtintores() async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_LISTAR_TIPOS_EXTINTORES),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Registra tipos de extintores
  Future<http.Response> registraTiposExtintores(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_REGISTRAR_TIPOS_EXTINTORES),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Para obtener todos los datos de tipos de extintores
  Future<http.Response> obtenerTiposExtintores(String id) async {
    final response = await http.get(
      Uri.parse(API_HOST + ENDPOINT_OBTENER_TIPOS_EXTINTORES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );
    return response;
  }

  // Actualizar tipos de extintores
  Future<http.Response> actualizarTiposExtintores(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_ACTUALIZAR_TIPOS_EXTINTORES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Eliminar tipos de extintores
  Future<http.Response> eliminarTiposExtintores(String id, Map<String, dynamic> data) async {
    final response = await http.delete(
      Uri.parse(API_HOST + ENDPOINT_ELIMINAR_TIPOS_EXTINTORES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }

  // Deshabilitar tipos de extintores
  Future<http.Response> actualizaDeshabilitarTiposExtintores(String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse(API_HOST + ENDPOINT_DESHABILITAR_TIPOS_EXTINTORES + '/$id'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return response;
  }
}
