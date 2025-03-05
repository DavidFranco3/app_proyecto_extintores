import 'package:universal_io/io.dart';
import '../../api/auth.dart';
import '../../api/logs.dart';
import '../../api/usuarios.dart';

Future<Map<String, dynamic>> _obtenerDatosComunes(String token) async {
  try {
    final authService = AuthService();
    final usuarioService = UsuariosService();

    // Obtener el id del usuario
    final idUsuario = await authService.obtenerIdUsuarioLogueado(token);
    print('ID Usuario obtenido: $idUsuario');

    // Obtener los datos del usuario
    Map<String, dynamic>? user = await usuarioService.obtenerUsuario2(idUsuario);
    print('Datos del usuario obtenidos: $user');

    if (user == null) {
      throw Exception("No se pudieron obtener los datos del usuario.");
    }

    final nombre = user['nombre'];
    final email = user['email'];

    // Obtener la IP
    final ipResponse = await LogsService().obtenIP();
    print('IP obtenida: $ipResponse');
    final ipTemp = ipResponse;

    // Obtener el número de logs
    final noLogResponse = await LogsService().obtenerNumeroLog();
    print('Respuesta número de log: $noLogResponse');
    final noLog = noLogResponse['noLog'];
    print('Número de log obtenido: $noLog');

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
    print('Token obtenido: $token');

    // Forzar que el token no sea null
    if (token == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await _obtenerDatosComunes(token);
    print('Datos comunes obtenidos: $datosComunes');

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

    print('Datos a registrar en el log: $dataTemp');

    final response = await LogsService().registraLog(dataTemp);
    print('Respuesta del registro de log: ${response.statusCode}, ${response.body}');

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
    print('Token obtenido para logout: $token');

    // Forzar que el token no sea null
    if (token == null) {
      throw Exception("Token de autenticación es nulo");
    }

    // Obtener los datos comunes utilizando el token
    final datosComunes = await _obtenerDatosComunes(token);
    print('Datos comunes obtenidos para logout: $datosComunes');

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

    print('Datos a registrar en el log de logout: $dataTemp');

    final response = await LogsService().registraLog(dataTemp);
    print('Respuesta del registro de log en logout: ${response.statusCode}, ${response.body}');

    if (response.statusCode == 200) {
      // Log registrado correctamente, proceder a hacer logout
      print('Log registrado correctamente, cerrando sesión...');
      await AuthService().logoutApi();
    } else {
      print('Error en el registro del log de logout: ${response.body}');
    }
  } catch (e) {
    print('Error al registrar log informativo en logout: $e');
  }
}
