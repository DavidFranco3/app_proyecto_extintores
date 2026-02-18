import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../utils/constants.dart';
import 'endpoints.dart';
import 'api_client.dart';

class AuthService {
  final _api = ApiClient().dio;

  // Validar inicio de sesión
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    try {
      final response = await _api.post(
        endpointLoginAdministrador,
        data: data,
      );

      if (response.statusCode == 200) {
        // Guardar el token en almacenamiento. Dio ya decodifica el JSON.
        String token = response.data['token'];
        await setTokenApi(token);
        return {'success': true, 'token': token};
      } else {
        return {'success': false, 'message': 'Error al iniciar sesión'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al iniciar sesión: $e'};
    }
  }

  // Guardar el token en almacenamiento local
  Future<void> setTokenApi(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Obtener el token
  Future<String?> getTokenApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Cerrar sesión
  Future<void> logoutApi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
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
    return JwtDecoder.isExpired(
        token); // Usando jwt_decoder para verificar expiración
  }

  // Obtener el usuario logueado a partir del token
  String obtenerIdUsuarioLogueado(String token) {
    Map<String, dynamic> decodedToken =
        JwtDecoder.decode(token); // Usando jwt_decoder
    return decodedToken['_'];
  }
}
