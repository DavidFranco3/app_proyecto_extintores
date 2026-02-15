import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth.dart';

final authService = AuthService();

class NotificacionesService {
  Future<Map<String, dynamic>> enviarNotificacion(
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
}


