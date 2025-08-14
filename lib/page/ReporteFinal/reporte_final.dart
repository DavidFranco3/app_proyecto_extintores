import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:prueba/page/RegistrarReporte/registrar_reporte.dart';
import '../../api/reporte_final.dart';
import '../../components/ReporteFinal/list_reporte_final.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ReporteFinalPage extends StatefulWidget {
  @override
  _ReporteFinalPageState createState() => _ReporteFinalPageState();
}

class _ReporteFinalPageState extends State<ReporteFinalPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataReporteFinal = [];
  bool showModal = false;

  late Box reporteBox;

  @override
  void initState() {
    super.initState();
    reporteBox = Hive.box('reporteFinalBox');
    cargarReporteFinal();
  }

  /// Verifica si hay conexión a internet
  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion == ConnectivityResult.none) return false;
    return await InternetConnection().hasInternetAccess;
  }

  /// Carga el reporte final según la conexión
  Future<void> cargarReporteFinal() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getReporteFinalDesdeAPI();
      } else {
        await getReporteFinalDesdeHive();
      }
    } catch (e) {
      print("Error general al cargar reporte final: $e");
      setState(() {
        dataReporteFinal = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// Obtiene los datos desde la API y los guarda en Hive
  Future<void> getReporteFinalDesdeAPI() async {
    final reporteFinalService = ReporteFinalService();
    final List<dynamic> response =
        await reporteFinalService.listarReporteFinal();

    if (response.isNotEmpty) {
      final formateadas = formatModelReporteFinal(response)
          .where((item) => item['estado'] == "true") // Filtrar activos
          .toList();

      await reporteBox.put('reportes', formateadas);

      setState(() {
        dataReporteFinal = formateadas;
      });
    } else {
      setState(() {
        dataReporteFinal = [];
      });
    }
  }

  /// Obtiene los datos guardados localmente en Hive
  Future<void> getReporteFinalDesdeHive() async {
    final List<dynamic>? guardadas = reporteBox.get('reportes');

    if (guardadas != null) {
      final locales = List<Map<String, dynamic>>.from(
        guardadas.map((e) => Map<String, dynamic>.from(e)),
      );

      setState(() {
        dataReporteFinal =
            locales.where((item) => item['estado'] == "true").toList();
      });
    }
  }

  /// Formatea los datos para el modelo
  List<Map<String, dynamic>> formatModelReporteFinal(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'descripcion': item['descripcion'],
        'imagenes': item['imagenes'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  /// Abre la pantalla de registro
  void openRegistroModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarReporteScreen(
          showModal: () {
            Navigator.pop(context);
          },
          onCompleted: cargarReporteFinal,
          accion: "registrar",
          data: null,
        ),
      ),
    );
  }

  /// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(
        currentPage: "Reporte de Actividades y pruebas",
      ),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Reporte de Actividades y pruebas",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed: openRegistroModal,
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblReporteFinal(
                    showModal: () {
                      Navigator.pop(context);
                    },
                    reporteFinal: dataReporteFinal,
                    onCompleted: cargarReporteFinal,
                  ),
                ),
              ],
            ),
      floatingActionButton: showModal
          ? FloatingActionButton(
              onPressed: closeModal,
              child: Icon(Icons.close),
            )
          : null,
    );
  }
}
