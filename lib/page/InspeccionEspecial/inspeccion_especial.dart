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
import '../../components/Generales/premium_button.dart';

class InspeccionEspecialPage extends StatefulWidget {
  const InspeccionEspecialPage({super.key});

  @override
  State<InspeccionEspecialPage> createState() => _InspeccionEspecialPageState();
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
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
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
      debugPrint("Sin conexión. Leyendo inspecciones desde Hive...");
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
      debugPrint("Error al obtener inspecciones: $e");
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
          dataInspecciones = almacenadas
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
        });
      } else {
        setState(() {
          dataInspecciones = [];
        });
      }
    } catch (e) {
      debugPrint("Error leyendo inspecciones desde Hive: $e");
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
            if (mounted) Navigator.pop(context);
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
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    children: [
                      const Text(
                        "Actividad anual",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      PremiumActionButton(
                        onPressed: openRegistroPage,
                        label: "Registrar",
                        icon: FontAwesomeIcons.plus,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 20, endIndent: 20, height: 32),
                Expanded(
                  child: TblInspeccionEspecial(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
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
