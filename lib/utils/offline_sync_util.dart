import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../api/inspecciones.dart';
import '../api/encuesta_inspeccion.dart';
import '../api/encuesta_inspeccion_cliente.dart';
import '../api/reporte_final.dart';

class OfflineSyncUtil {
  static final OfflineSyncUtil _instance = OfflineSyncUtil._internal();
  factory OfflineSyncUtil() => _instance;
  OfflineSyncUtil._internal();

  final ValueNotifier<int> pendingCount = ValueNotifier<int>(0);

  void init() {
    _updatePendingCount();
    // Escuchar cambios en las cajas principales para actualizar el contador
    Hive.box('encuestasPendientes')
        .listenable()
        .addListener(_updatePendingCount);
    Hive.box('operacionesOfflineEncuestas')
        .listenable()
        .addListener(_updatePendingCount);
    Hive.box('operacionesOfflineInspecciones')
        .listenable()
        .addListener(_updatePendingCount);
    Hive.box('operacionesOfflinePreguntas')
        .listenable()
        .addListener(_updatePendingCount);
    Hive.box('operacionesOfflineReportes')
        .listenable()
        .addListener(_updatePendingCount);
  }

  void _updatePendingCount() {
    int total = 0;
    try {
      total += (Hive.box('encuestasPendientes')
              .get('encuestas', defaultValue: []) as List)
          .length;
      total += (Hive.box('operacionesOfflineEncuestas')
              .get('operaciones', defaultValue: []) as List)
          .length;
      total += (Hive.box('operacionesOfflineInspecciones')
              .get('operaciones', defaultValue: []) as List)
          .length;
      total += (Hive.box('operacionesOfflinePreguntas')
              .get('operaciones', defaultValue: []) as List)
          .length;
      total += (Hive.box('operacionesOfflineReportes')
              .get('operaciones', defaultValue: []) as List)
          .length;
    } catch (e) {
      debugPrint("Error calculando pendientes: $e");
    }
    pendingCount.value = total;
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> sincronizarTodo() async {
    if (!await verificarConexion()) return;
    debugPrint("🔄 Iniciando sincronización global...");

    await sincronizarEncuestasPendientes();
    await sincronizarOperacionesEncuestas();
    await sincronizarOperacionesInspecciones();
    await sincronizarOperacionesPreguntas();
    await sincronizarOperacionesReportes();

    debugPrint("✔ Sincronización global finalizada.");
  }

  Future<void> sincronizarEncuestasPendientes() async {
    final box = Hive.box('encuestasPendientes');
    final pendientesRaw = box.get('encuestas', defaultValue: []);
    final List<Map<String, dynamic>> pendientes = (pendientesRaw as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (pendientes.isEmpty) return;

    final inspeccionesService = InspeccionesService();
    final List<int> eliminarIndices = [];

    for (int i = 0; i < pendientes.length; i++) {
      final operacion = pendientes[i];
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;

      try {
        if (operacion['accion'] == 'registrar') {
          final response =
              await inspeccionesService.registraInspecciones(operacion['data']);
          if (response['status'] == 200 ||
              (response['status'] >= 400 && response['status'] < 500) ||
              operacion['intentos'] >= 5) {
            eliminarIndices.add(i);
          }
        }
      } catch (e) {
        if (operacion['intentos'] >= 5) eliminarIndices.add(i);
      }
    }

    final nuevas = pendientes
        .asMap()
        .entries
        .where((e) => !eliminarIndices.contains(e.key))
        .map((e) => e.value)
        .toList();
    await box.put('encuestas', nuevas);
  }

  Future<void> sincronizarOperacionesEncuestas() async {
    final box = Hive.box('operacionesOfflineEncuestas');
    final operacionesRaw = box.get('operaciones', defaultValue: []);
    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final encuestasService = EncuestaInspeccionService();
    final List<String> eliminarIds = [];

    for (var operacion in operaciones) {
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;
      try {
        Map<String, dynamic>? response;
        if (operacion['accion'] == 'registrar') {
          response = await encuestasService
              .registraEncuestaInspeccion(operacion['data']);
        } else if (operacion['accion'] == 'editar') {
          response = await encuestasService.actualizarEncuestaInspeccion(
              operacion['id'], operacion['data']);
        } else if (operacion['accion'] == 'eliminar') {
          response = await encuestasService.deshabilitarEncuestaInspeccion(
              operacion['id'], {'estado': 'false'});
        }

        if (response != null) {
          final status = response['status'];
          if (status == 200 ||
              (status >= 400 && status < 500) ||
              operacion['intentos'] >= 5) {
            eliminarIds.add(operacion['operacionId'] ?? "");
          }
        }
      } catch (e) {
        if (operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['operacionId'] ?? "");
        }
      }
    }

    final nuevas = operaciones
        .where((op) => !eliminarIds.contains(op['operacionId']))
        .toList();
    await box.put('operaciones', nuevas);
  }

  Future<void> sincronizarOperacionesInspecciones() async {
    final box = Hive.box('operacionesOfflineInspecciones');
    final operacionesRaw = box.get('operaciones', defaultValue: []);
    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final inspeccionesService = InspeccionesService();
    final List<int> eliminarIndices = [];

    for (int i = 0; i < operaciones.length; i++) {
      final operacion = operaciones[i];
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;

      try {
        final response = await inspeccionesService
            .actualizarImagenesInspecciones(operacion['id'], operacion['data']);
        if (response['status'] == 200 ||
            (response['status'] >= 400 && response['status'] < 500) ||
            operacion['intentos'] >= 5) {
          eliminarIndices.add(i);
        }
      } catch (e) {
        if (operacion['intentos'] >= 5) eliminarIndices.add(i);
      }
    }

    final nuevas = operaciones
        .asMap()
        .entries
        .where((e) => !eliminarIndices.contains(e.key))
        .map((e) => e.value)
        .toList();
    await box.put('operaciones', nuevas);
  }

  Future<void> sincronizarOperacionesPreguntas() async {
    final box = Hive.box('operacionesOfflinePreguntas');
    final operacionesRaw = box.get('operaciones', defaultValue: []);
    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final service = EncuestaInspeccionClienteService();
    final List<String> eliminarIds = [];

    for (var operacion in operaciones) {
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;
      try {
        final response =
            await service.registraEncuestaInspeccionCliente(operacion['data']);
        final status = response['status'];
        if (status == 200 ||
            (status >= 400 && status < 500) ||
            operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['idTemporal'] ?? "");
        }
      } catch (e) {
        if (operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['idTemporal'] ?? "");
        }
      }
    }

    final nuevas = operaciones
        .where((op) => !eliminarIds.contains(op['idTemporal']))
        .toList();
    await box.put('operaciones', nuevas);
  }

  Future<void> sincronizarOperacionesReportes() async {
    final box = Hive.box('operacionesOfflineReportes');
    final operacionesRaw = box.get('operaciones', defaultValue: []);
    final List<Map<String, dynamic>> operaciones = (operacionesRaw as List)
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();

    if (operaciones.isEmpty) return;

    final service = ReporteFinalService();
    final List<String> eliminarIds = [];

    for (var operacion in operaciones) {
      operacion['intentos'] = (operacion['intentos'] ?? 0) + 1;
      try {
        final response = await service.registrarReporteFinal(operacion['data']);
        final status = response['status'];
        if (status == 200 ||
            (status >= 400 && status < 500) ||
            operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['operacionId'] ?? "");
        }
      } catch (e) {
        if (operacion['intentos'] >= 5) {
          eliminarIds.add(operacion['operacionId'] ?? "");
        }
      }
    }

    final nuevas = operaciones
        .where((op) => !eliminarIds.contains(op['operacionId']))
        .toList();
    await box.put('operaciones', nuevas);
  }
}
