import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import 'endpoints.dart';

class NotificacionesService {
  Future<Map<String, dynamic>> enviarNotificacion(
      Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_ENVIAR_NOTIFICACION),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );
    return {
      'body': jsonDecode(response.body),
      'status': response.statusCode, // Retorna la respuesta del servidor
    };
  }
}
