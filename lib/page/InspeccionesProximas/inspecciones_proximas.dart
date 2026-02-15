import 'package:flutter/material.dart';
import '../../api/inspecciones_proximas.dart';
import '../../components/InspeccionesProximas/list_inspecciones_proximas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class InspeccionesProximasPage extends StatefulWidget {
  const InspeccionesProximasPage({super.key});

  @override
  State<InspeccionesProximasPage> createState() =>
      _InspeccionesProximasPageState();
}

class _InspeccionesProximasPageState extends State<InspeccionesProximasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspeccionesProximas = [];

  @override
  void initState() {
    super.initState();
    cargarInspeccionesProximas();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> cargarInspeccionesProximas() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        debugPrint("Conectado a internet");
        await getInspeccionesProximasDesdeAPI();
      } else {
        debugPrint("Sin conexión, cargando inspecciones próximas desde Hive...");
        await getInspeccionesProximasDesdeHive();
      }
    } catch (e) {
      debugPrint("Error general al cargar inspecciones próximas: $e");
      setState(() {
        dataInspeccionesProximas = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getInspeccionesProximasDesdeAPI() async {
    final inspeccionesProximasService = InspeccionesProximasService();
    final List<dynamic> response =
        await inspeccionesProximasService.listarInspeccionesProximas();

    if (response.isNotEmpty) {
      final formateadas = formatModelInspeccionesProximas(response);

      // Guardar en Hive
      final box = Hive.box('inspeccionesProximasBox');
      await box.put('inspecciones_proximas', formateadas);

      setState(() {
        dataInspeccionesProximas = formateadas;
      });
    } else {
      setState(() {
        dataInspeccionesProximas = [];
      });
    }
  }

  Future<void> getInspeccionesProximasDesdeHive() async {
    final box = Hive.box('inspeccionesProximasBox');
    final List<dynamic>? guardadas = box.get('inspecciones_proximas');

    if (guardadas != null) {
      setState(() {
        dataInspeccionesProximas = List<Map<String, dynamic>>.from(
            guardadas.map((e) => Map<String, dynamic>.from(e))
            .where((item) => item['estado'] == "true"));

      });
    } else {
      setState(() {
        dataInspeccionesProximas = [];
      });
    }
  }

  List<Map<String, dynamic>> formatModelInspeccionesProximas(
      List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'idCliente': item['idCliente'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['frecuencia']['nombre'],
        'cliente': item['cliente']['nombre'],
        'proximaInspeccion': item['nuevaInspeccion'],
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
      drawer: MenuLateral(currentPage: "Actividades próximas"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Actividades próximas",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TblInspeccionesProximas(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
                    },
                    inspeccionesProximas: dataInspeccionesProximas,
                    onCompleted: cargarInspeccionesProximas,
                  ),
                ),
              ],
            ),
    );
  }
}


