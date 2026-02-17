import 'package:flutter/material.dart';
import '../../api/logs.dart';
import '../../components/Logs/list_logs.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataLogs = [];

  @override
  void initState() {
    super.initState();
    cargarLogs();
  }

  Future<void> cargarLogs() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        debugPrint("Conectado a internet");
        await getLogsDesdeAPI();
      } else {
        debugPrint("Sin conexión, cargando logs desde Hive...");
        await getLogsDesdeHive();
      }
    } catch (e) {
      debugPrint("Error al cargar logs: $e");
      setState(() {
        dataLogs = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getLogsDesdeAPI() async {
    final logsService = LogsService();
    final List<dynamic> response = await logsService.listarLogs();

    if (response.isNotEmpty) {
      final formateados = formatModelLogs(response);

      // Guardar localmente
      final box = Hive.box('logsBox');
      await box.put('logs', formateados);

      setState(() {
        dataLogs = formateados;
      });
    } else {
      setState(() {
        dataLogs = [];
      });
    }
  }

  Future<void> getLogsDesdeHive() async {
    final box = Hive.box('logsBox');
    final List<dynamic>? guardados = box.get('logs');

    if (guardados != null) {
      setState(() {
        dataLogs = List<Map<String, dynamic>>.from(guardados
            .map((e) => Map<String, dynamic>.from(e))
            .where((item) => item['estado'] == "true"));
      });
    } else {
      setState(() {
        dataLogs = [];
      });
    }
  }

  List<Map<String, dynamic>> formatModelLogs(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'folio': item['folio'],
        'usuario': item['usuario'],
        'correo': item['correo'],
        'dispositivo': item['dispositivo'],
        'ip': item['ip'],
        'descripcion': item['descripcion'],
        'detalles': item['detalles']['mensaje'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Logs"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: Center(
                          child: Text(
                            "Logs de auditoría",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2C3E50),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TblLogs(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
                    },
                    logs: dataLogs,
                    onCompleted: cargarLogs,
                  ),
                ),
              ],
            ),
    );
  }
}
