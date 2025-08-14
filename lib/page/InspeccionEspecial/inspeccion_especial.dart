import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../api/inspeccion_anual.dart';
import '../../components/InspeccionEspecial/list_inspeccion_especial.dart';
import '../InspeccionAnual/inspeccion_anual.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionEspecialPage extends StatefulWidget {
  @override
  _InspeccionEspecialPageState createState() => _InspeccionEspecialPageState();
}

class _InspeccionEspecialPageState extends State<InspeccionEspecialPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];
  bool showModal = false;

  @override
  void initState() {
    super.initState();
    // Asegúrate de abrir la caja antes de usarla
    Hive.openBox('inspeccionAnualBox').then((_) {
      getInspecciones();
    });
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion == ConnectivityResult.none) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getInspecciones() async {
    setState(() {
      loading = true;
    });

    final conectado = await verificarConexion();

    if (conectado) {
      await getInspeccionesDesdeAPI();
    } else {
      print("Sin conexión. Leyendo inspecciones desde Hive...");
      await getInspeccionesDesdeHive();
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> getInspeccionesDesdeAPI() async {
    try {
      final inspeccionAnualService = InspeccionAnualService();
      final List<dynamic> response =
          await inspeccionAnualService.listarInspeccionAnual();

      if (response.isNotEmpty) {
        final formateadas = formatModelInspecciones(response);

        final box = Hive.box('inspeccionAnualBox');
        await box.put('inspecciones', formateadas);

        setState(() {
          dataInspecciones = formateadas;
        });
      } else {
        setState(() {
          dataInspecciones = [];
        });
      }
    } catch (e) {
      print("Error al obtener inspecciones: $e");
      setState(() {
        dataInspecciones = [];
      });
    }
  }

  Future<void> getInspeccionesDesdeHive() async {
    try {
      final box = Hive.box('inspeccionAnualBox');
      final List<dynamic>? almacenadas = box.get('inspecciones');

      if (almacenadas != null) {
        setState(() {
          dataInspecciones = (almacenadas as List)
              .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
        });
      } else {
        setState(() {
          dataInspecciones = [];
        });
      }
    } catch (e) {
      print("Error leyendo inspecciones desde Hive: $e");
      setState(() {
        dataInspecciones = [];
      });
    }
  }

  void openRegistroPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InspeccionAnualPage(
          showModal: () {
            Navigator.pop(context);
          },
          onCompleted: getInspecciones,
          accion: "registrar",
          data: null,
        ),
      ),
    );
  }

  void closeModal() {
    setState(() {
      showModal = false;
    });
  }

  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
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
      drawer: MenuLateral(currentPage: "Actividad anual"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Actividad anual",
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
                      onPressed: openRegistroPage,
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblInspeccionEspecial(
                    showModal: () {
                      Navigator.pop(context);
                    },
                    inspeccionAnual: dataInspecciones,
                    onCompleted: getInspecciones,
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
