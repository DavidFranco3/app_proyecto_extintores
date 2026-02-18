import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/inspecciones.dart';
import '../api/inspecciones_proximas.dart';
import '../api/tokens.dart';
import '../api/auth.dart';
import '../api/usuarios.dart';
import '../api/logs.dart';
import '../api/notificaciones.dart';
import 'base_controller.dart';

class HomeController extends BaseController {
  bool _isInitialized = false;
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  List<Map<String, dynamic>> dataInspeccionesProximas2 = [];
  List<Map<String, dynamic>> dataTokens = [];
  String nombreUsuario = "Usuario";
  int pendingOperations = 0;
  List<Map<String, dynamic>> recentLogs = [];

  final _authService = AuthService();
  final _usuarioService = UsuariosService();
  final _tokensService = TokensService();
  final _inspeccionesService = InspeccionesService();
  final _proximasService = InspeccionesProximasService();
  final _logsService = LogsService();
  final _notificacionesService = NotificacionesService();

  Timer? _notificationTimer;

  Future<void> init() async {
    if (_isInitialized && !loading) return;
    _isInitialized = true;
    await cargarDatos();
    scheduleDailyNotification();
  }

  Future<void> cargarDatos() async {
    setLoading(true);

    try {
      await Future.wait([
        getInspecciones(),
        getInspeccionesProximas(),
        getTokens(),
        obtenerNombreUsuario(),
        checkPendingOperations(),
        getRecentLogs(),
      ]);
    } catch (e) {
      debugPrint("❌ Error crítico cargando datos del Home: $e");
    } finally {
      setLoading(false);
    }
  }

  Future<void> obtenerNombreUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? nombre = prefs.getString('nombreUsuario');
      if (nombre != null) {
        nombreUsuario = nombre;
        notifyListeners();
      }

      if (await connectivity.isConnected) {
        final token = await _authService.getTokenApi();
        if (token != null) {
          final idUsuario = _authService.obtenerIdUsuarioLogueado(token);
          final user = await _usuarioService.obtenerUsuario2(idUsuario);
          if (user != null && user['nombre'] != null) {
            nombreUsuario = user['nombre'];
            await prefs.setString('nombreUsuario', user['nombre']);
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo nombre de usuario: $e");
    }
  }

  Future<void> getTokens() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _tokensService.listarTokens(),
      cacheBox: 'tokensBox',
      cacheKey: 'tokens',
      onDataReceived: (data) {
        final filtered = data
            .where((item) => item['usuario']['tipo'] == 'inspector')
            .toList();
        dataTokens = _formatModelTokens(filtered);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataTokens = _formatModelTokens(
              cachedData.map((e) => Map<String, dynamic>.from(e)).toList());
        }
      },
    );
  }

  Future<void> getInspecciones() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _inspeccionesService.listarInspecciones(),
      cacheBox: 'inspeccionesBox',
      cacheKey: 'inspecciones',
      onDataReceived: (data) {
        dataInspecciones = _formatModelInspecciones(data);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          dataInspecciones = _formatModelInspecciones(
              cachedData.map((e) => Map<String, dynamic>.from(e)).toList());
        }
      },
    );
  }

  Future<void> getInspeccionesProximas() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _proximasService.listarInspeccionesProximas(),
      cacheBox: 'inspeccionesProximasBox',
      cacheKey: 'inspeccionesProximas',
      onDataReceived: (data) {
        final formatted = _formatModelInspeccionesProximas(data);
        dataInspeccionesProximas = formatted;
        _filtrarProximas(formatted);
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          final lista =
              cachedData.map((e) => Map<String, dynamic>.from(e)).toList();
          dataInspeccionesProximas = lista;
          _filtrarProximas(lista);
        }
      },
      formatToCache: (data) => _formatModelInspeccionesProximas(data),
    );
  }

  void _filtrarProximas(List<Map<String, dynamic>> lista) {
    final fechaActual = DateTime.now();
    dataInspeccionesProximas2 = lista.where((item) {
      final String? proximaString = item['proximaInspeccion'];
      if (proximaString == null) return false;

      final proximaFecha = DateTime.tryParse(proximaString);
      if (proximaFecha == null) return false;

      return proximaFecha.difference(fechaActual).inDays <= 3 &&
          proximaFecha.isAfter(fechaActual);
    }).toList();
  }

  Future<void> checkPendingOperations() async {
    try {
      pendingOperations = await queue.queueLength;
      notifyListeners();
    } catch (e) {
      debugPrint("Error checking pending operations: $e");
    }
  }

  Future<void> getRecentLogs() async {
    await fetchData<List<dynamic>>(
      fetchFromApi: () => _logsService.listarLogs(),
      cacheBox: 'logsBox',
      cacheKey: 'logs',
      onDataReceived: (data) {
        recentLogs =
            data.take(5).map((e) => Map<String, dynamic>.from(e)).toList();
      },
      onCacheLoaded: (cachedData) {
        if (cachedData is List) {
          recentLogs = cachedData
              .take(5)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      },
    );
  }

  void scheduleDailyNotification() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(hours: 24), (_) async {
      await enviarNotificacionAlBackend();
    });
  }

  Future<void> enviarNotificacionAlBackend() async {
    List<Future<void>> requests = [];
    for (var tokenData in dataTokens) {
      for (var inspeccionData in dataInspeccionesProximas2) {
        final formData = {
          "titulo": "Recordatorio de inspección",
          "token": tokenData["token"],
          "mensaje":
              "Se debe realizar la inspección de ${inspeccionData["cuestionario"]["nombre"]}"
        };
        requests.add(_notificacionesService.enviarNotificacion(formData));
      }
    }
    try {
      await Future.wait(requests);
    } catch (e) {
      debugPrint("Error al enviar notificaciones: $e");
    }
  }

  List<Map<String, dynamic>> _formatModelTokens(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'idUsuario': item['idUsuario'],
              'token': item['token'],
              'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
              'tipo': item['usuario']?['tipo'] ?? 'Sin tipo',
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  List<Map<String, dynamic>> _formatModelInspecciones(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'idUsuario': item['idUsuario'],
              'idCliente': item['idCliente'],
              'idEncuesta': item['idEncuesta'],
              'encuesta': item['encuesta'],
              'imagenes': item['imagenes'],
              'comentarios': item['comentarios'],
              'usuario': item['usuario']?['nombre'] ?? 'Sin usuario',
              'cliente': item['cliente']?['nombre'] ?? 'Sin cliente',
              'cuestionario':
                  item['cuestionario']?['nombre'] ?? 'Sin cuestionario',
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  List<Map<String, dynamic>> _formatModelInspeccionesProximas(
      List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'idFrecuencia': item['idFrecuencia'],
              'idEncuesta': item['idEncuesta'],
              'cuestionario': item['cuestionario']?['nombre'] ?? 'Sin nombre',
              'frecuencia': item['frecuencia']?['nombre'] ?? 'Sin frecuencia',
              'proximaInspeccion': item['nuevaInspeccion'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  @override
  void dispose() {
    _notificationTimer?.cancel();
    super.dispose();
  }
}
