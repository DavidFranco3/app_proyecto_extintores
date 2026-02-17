import 'package:flutter/material.dart';
import 'package:prueba/components/Generales/grafico_lineas.dart';
import '../../api/inspeccion_anual.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GraficaDatosInspeccionesPage extends StatefulWidget {
  final String idInspeccion;

  const GraficaDatosInspeccionesPage({super.key, required this.idInspeccion});

  @override
  State<GraficaDatosInspeccionesPage> createState() =>
      _GraficaDatosInspeccionesPageState();
}

class _GraficaDatosInspeccionesPageState
    extends State<GraficaDatosInspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataEncuestas = [];
  late Box inspeccionAnualBox;

  @override
  void initState() {
    super.initState();
    inspeccionAnualBox = Hive.box('inspeccionAnualBox');
    cargarEncuestas();
  }

  /// Verifica conexión a internet
  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  /// Decide de dónde cargar datos (API o Hive)
  Future<void> cargarEncuestas() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getEncuestasDesdeAPI();
      } else {
        await getEncuestasDesdeHive();
      }
    } catch (e) {
      debugPrint("Error general al cargar inspección anual: $e");
      setState(() {
        dataEncuestas = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// Obtiene encuestas desde API y guarda en Hive
  Future<void> getEncuestasDesdeAPI() async {
    final inspeccionAnualService = InspeccionAnualService();
    final List<dynamic> response = await inspeccionAnualService
        .listarInspeccionAnualId(widget.idInspeccion);

    if (response.isNotEmpty) {
      final formateadas = formatModelEncuestas(response)
          .where((item) => item['estado'] == "true")
          .toList();

      // Guardar en Hive usando idInspeccion como clave
      await inspeccionAnualBox.put(widget.idInspeccion, formateadas);

      setState(() {
        dataEncuestas = formateadas;
      });
    } else {
      setState(() {
        dataEncuestas = [];
      });
    }
  }

  /// Obtiene encuestas desde Hive
  Future<void> getEncuestasDesdeHive() async {
    final List<dynamic>? guardadas =
        inspeccionAnualBox.get(widget.idInspeccion);

    if (guardadas != null) {
      final locales = List<Map<String, dynamic>>.from(
        guardadas.map((e) => Map<String, dynamic>.from(e)),
      );

      setState(() {
        dataEncuestas =
            locales.where((item) => item['estado'] == "true").toList();
      });
    }
  }

  /// Formatea los datos recibidos
  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'titulo': item['titulo'],
        'idCliente': item['idCliente'],
        'datos': item['datos'],
        'cliente': item['cliente']['nombre'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Gráfico de actividades"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Center(
                    child: Text(
                      "Gráfico de Datos",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2C3E50),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GraficaLineas(
                    encuestaAbierta: dataEncuestas,
                  ),
                ),
              ],
            ),
    );
  }
}
