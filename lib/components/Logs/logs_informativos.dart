import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/auth.dart';
import '../../api/logs.dart';
import '../../api/usuarios.dart';

Future<Map<String, dynamic>> _obtenerDatosComunes(String token) async {
  try {
    final authService = AuthService();
    final usuarioService = UsuarioService();

    // Obtener el id del usuario
    final idUsuario = await authService.obtenidusuarioLogueado(token);
    
    // Obtener los datos del usuario
    Map<String, dynamic>? user = await usuarioService.obtenerUsuario2(idUsuario?['id'] ?? '');
    if (user == null || user['data'] == null) {
      throw Exception("No se pudieron obtener los datos del usuario.");
    }

    final nombre = user['data']['nombre'];
    final email = user['data']['email'];

    // Obtener la IP
    final ipResponse = await LogsService().obtenIP();
    final ipTemp = ipResponse['data'];

    // Obtener el número de logs
    final noLogResponse = await LogsService().obtenerNumeroLog();
    final noLog = noLogResponse['data']['noLog'];

    return {
      'nombre': nombre,
      'email': email,
      'ip': ipTemp,
      'noLog': noLog,
    };
  } catch (e) {
    print('Error al obtener datos comunes: $e');
    rethrow; // Lanza el error para que lo maneje la función que lo llamó
  }
}

Future<void> LogsInformativos(String mensaje, Map<String, dynamic> datos) async {
  try {
    // Obtener el token de autenticación
    final String? token = await AuthService().getTokenApi();
    
    // Forzar que el token no sea null
    final String tokenNoNulo = token!;  // Si token es null, lanzará una excepción

    // Obtener los datos comunes utilizando el token
    final datosComunes = await _obtenerDatosComunes(tokenNoNulo);

    Map<String, dynamic> dataTemp = {
      'folio': datosComunes['noLog'],
      'usuario': datosComunes['nombre'],
      'correo': datosComunes['email'],
      'dispositivo': 'navigator.platform',
      'ip': datosComunes['ip'],
      'descripcion': 'navigator.userAgent',
      'detalles': {
        'mensaje': mensaje,
        'datos': datos,
      }
    };

    final response = await LogsService().registraLog(dataTemp);
    if (response.statusCode == 200) {
      print('Log registrado correctamente');
    } else {
      print('Error en el registro del log: ${response.body}');
    }
  } catch (e) {
    print('Error al registrar log informativo: $e');
  }
}

Future<void> LogsInformativosLogout(String mensaje) async {
  try {
    // Obtener el token de autenticación
    final String? token = await AuthService().getTokenApi();
    
    // Forzar que el token no sea null
    final String tokenNoNulo = token!;  // Si token es null, lanzará una excepción

    // Obtener los datos comunes utilizando el token
    final datosComunes = await _obtenerDatosComunes(tokenNoNulo);

    final dataTemp = {
      'folio': datosComunes['noLog'],
      'usuario': datosComunes['nombre'],
      'correo': datosComunes['email'],
      'dispositivo': 'navigator.platform',
      'ip': datosComunes['ip'],
      'descripcion': 'navigator.userAgent',
      'detalles': {
        'mensaje': mensaje,
      }
    };

    final response = await LogsService().registraLog(dataTemp);
    if (response.statusCode == 200) {
      // Log registrado correctamente, proceder a hacer logout
      await AuthService().logoutApi();
    } else {
      print('Error en el registro del log: ${response.body}');
    }
  } catch (e) {
    print('Error al registrar log informativo en logout: $e');
  }
}
