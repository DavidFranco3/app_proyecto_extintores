import 'package:flutter/material.dart';
import '../../api/inspecciones_proximas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/calendario.dart';
import '../../components/Generales/event.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ProgramaInspeccionesPage extends StatefulWidget {
  const ProgramaInspeccionesPage({super.key});

  @override
  State<ProgramaInspeccionesPage> createState() =>
      _ProgramaInspeccionesPageState();
}

class _ProgramaInspeccionesPageState extends State<ProgramaInspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  late List<Event> eventosCalendario = [];

  @override
  void initState() {
    super.initState();
    cargarInspecciones();
  }

  Future<void> cargarInspecciones() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getInspeccionesDesdeAPI();
      } else {
        await getInspeccionesDesdeHive();
      }
    } catch (e) {
      debugPrint("Error general al cargar inspecciones: $e");
      setState(() {
        dataInspeccionesProximas = [];
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

  Future<void> getInspeccionesDesdeAPI() async {
    final inspeccionesService = InspeccionesProximasService();
    final List<dynamic> response =
        await inspeccionesService.listarInspeccionesProximas();

    if (response.isNotEmpty) {
      final formateadas = formatModelInspeccionesProximas(response);

      final box = Hive.box('inspeccionesProximasBox');
      await box.put('inspecciones', formateadas);

      setState(() {
        dataInspeccionesProximas = formateadas;
        eventosCalendario = _convertirAEventosCalendario(formateadas);
      });
    }
  }

  Future<void> getInspeccionesDesdeHive() async {
    final box = Hive.box('inspeccionesProximasBox');
    final List<dynamic>? guardadas = box.get('inspecciones');

    if (guardadas != null) {
      final locales = List<Map<String, dynamic>>.from(guardadas
          .map((e) => Map<String, dynamic>.from(e))
          .where((item) => item['estado'] == "true"));

      setState(() {
        dataInspeccionesProximas = locales;
        eventosCalendario = _convertirAEventosCalendario(locales);
      });
    }
  }

  List<Map<String, dynamic>> formatModelInspeccionesProximas(
      List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
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

  List<Event> _convertirAEventosCalendario(List<Map<String, dynamic>> data) {
    return data.map<Event>((item) {
      DateTime fechaInspeccion = DateTime.parse(item['proximaInspeccion']);
      String evento =
          "Cliente: ${item['cliente']} - Inspección: ${item['cuestionario']}";
      return Event(title: evento, date: fechaInspeccion);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Programa de actividades"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Programa de actividades",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Calendario(eventosIniciales: eventosCalendario),
                ),
              ],
            ),
    );
  }
}

