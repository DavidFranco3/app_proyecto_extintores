import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import '../../api/auth.dart';
import '../../api/logs.dart';
import '../../api/usuarios.dart';

Future<Map<String, dynamic>> _obtenerDatosComunes(String token) async {
  try {
    final authService = AuthService();
    final usuarioService = UsuariosService();

    // Obtener el id del usuario
    final idUsuario = authService.obtenerIdUsuarioLogueado(token);
    debugPrint('ID Usuario obtenido: $idUsuario');

    // Obtener los datos del usuario
    Map<String, dynamic>? user =
        await usuarioService.obtenerUsuario2(idUsuario);
    debugPrint('Datos del usuario obtenidos: $user');

    if (user == null) {
      throw Exception("No se pudieron obtener los datos del usuario.");
    }

    final nombre = user['nombre'];
    final email = user['email'];

    // Obtener la IP
    final ipResponse = await LogsService().obtenIP();
    debugPrint('IP obtenida: $ipResponse');
    final ipTemp = ipResponse;

    // Obtener el número de logs
    final noLogResponse = await LogsService().obtenerNumeroLog();
    debugPrint('Respuesta número de log: $noLogResponse');
    final noLog = noLogResponse['noLog'];
    debugPrint('Número de log obtenido: $noLog');

    return {
      'nombre': nombre,
      'email': email,
      'ip': ipTemp,
      'noLog': noLog,
    };
  } catch (e) {
    debugPrint('Error al obtener datos comunes: $e');
    rethrow; // Lanza el error para que lo maneje la función que lo llamó
  }
}

Future<void> logsInformativos(
    String mensaje, Map<String, dynamic> datos) async {
  try {
    // Obtener el token de autenticación
    final String? token = await AuthService().getTokenApi();
    debugPrint('Token obtenido: $token');

    // Forzar que el token no sea null
    if (token == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await _obtenerDatosComunes(token);
    debugPrint('Datos comunes obtenidos: $datosComunes');

    // Obtener información del dispositivo
    final dispositivo = Platform.isAndroid
        ? "Android"
        : Platform.isIOS
            ? "iOS"
            : Platform.isWindows
                ? "Windows"
                : Platform.isMacOS
                    ? "MacOS"
                    : Platform.isLinux
                        ? "Linux"
                        : "Web";

    final descripcion = Platform.operatingSystemVersion;

    Map<String, dynamic> dataTemp = {
      'folio': datosComunes['noLog'],
      'usuario': datosComunes['nombre'],
      'correo': datosComunes['email'],
      'dispositivo': dispositivo,
      'ip': datosComunes['ip'],
      'descripcion': descripcion,
      'detalles': {
        'mensaje': mensaje,
        'datos': datos,
      }
    };

    debugPrint('Datos a registrar en el log: $dataTemp');

    final response = await LogsService().registraLog(dataTemp);
    debugPrint(
        'Respuesta del registro de log: ${response.statusCode}, ${response.data}');

    if (response.statusCode == 200) {
      debugPrint('Log registrado correctamente');
    } else {
      debugPrint('Error en el registro del log: ${response.data}');
    }
  } catch (e) {
    debugPrint('Error al registrar log informativo: $e');
  }
}

Future<void> logsInformativosLogout(String mensaje) async {
  try {
    // Obtener el token de autenticación
    final String? token = await AuthService().getTokenApi();
    debugPrint('Token obtenido para logout: $token');

    // Forzar que el token no sea null
    if (token == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await _obtenerDatosComunes(token);
    debugPrint('Datos comunes obtenidos para logout: $datosComunes');

    // Obtener información del dispositivo
    final dispositivo = Platform.isAndroid
        ? "Android"
        : Platform.isIOS
            ? "iOS"
            : Platform.isWindows
                ? "Windows"
                : Platform.isMacOS
                    ? "MacOS"
                    : Platform.isLinux
                        ? "Linux"
                        : "Web";

    final descripcion = Platform.operatingSystemVersion;

    final dataTemp = {
      'folio': datosComunes['noLog'],
      'usuario': datosComunes['nombre'],
      'correo': datosComunes['email'],
      'dispositivo': dispositivo,
      'ip': datosComunes['ip'],
      'descripcion': descripcion,
      'detalles': {
        'mensaje': mensaje,
      }
    };

    debugPrint('Datos a registrar en el log de logout: $dataTemp');

    final response = await LogsService().registraLog(dataTemp);
    debugPrint(
        'Respuesta del registro de log en logout: ${response.statusCode}, ${response.data}');

    if (response.statusCode == 200) {
      // Log registrado correctamente, proceder a hacer logout
      debugPrint('Log registrado correctamente, cerrando sesión...');
      await AuthService().logoutApi();
    } else {
      debugPrint('Error en el registro del log de logout: ${response.data}');
    }
  } catch (e) {
    debugPrint('Error al registrar log informativo en logout: $e');
  }
}
