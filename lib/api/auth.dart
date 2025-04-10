import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart'; // Reemplazamos jwt_decode por jwt_decoder
import 'endpoints.dart'; 
import '../utils/constants.dart'; 

class AuthService {
  // Validar inicio de sesión
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse(API_HOST + ENDPOINT_LOGIN_ADMINISTRADOR),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Guardar el token en almacenamiento
      String token = jsonDecode(response.body)['token'];
      await setTokenApi(token);
      return {'success': true, 'token': token};
    } else {
      return {'success': false, 'message': 'Error al iniciar sesión'};
    }
  }

  // Guardar el token en almacenamiento local
  Future<void> setTokenApi(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(TOKEN, token);
  }

  // Obtener el token
  Future<String?> getTokenApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(TOKEN);
  }

  // Cerrar sesión
  Future<void> logoutApi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(TOKEN);
  }

  // Obtener los datos del usuario logueado
  Future<Map<String, dynamic>?> isUserLoggedApi() async {
    String? token = await getTokenApi();
    if (token == null || isTokenExpired(token)) {
      await logoutApi();
      return null;
    }

    return JwtDecoder.decode(token); // Decodificar el token usando jwt_decoder
  }

  // Verificar si el token ha expirado
  bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token); // Usando jwt_decoder para verificar expiración
  }

  // Obtener el usuario logueado a partir del token
  String obtenerIdUsuarioLogueado(String token) {
    Map<String, dynamic> decodedToken = JwtDecoder.decode(token);  // Usando jwt_decoder
    return decodedToken['_'];
  }
}
