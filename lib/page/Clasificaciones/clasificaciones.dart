import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/clasificaciones.dart';
import '../../components/Clasificaciones/list_clasificaciones.dart';
import '../../components/Clasificaciones/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class ClasificacionesPage extends StatefulWidget {
  const ClasificacionesPage({super.key});

  @override
  State<ClasificacionesPage> createState() => _ClasificacionesPageState();
}

class _ClasificacionesPageState extends State<ClasificacionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataClasificaciones = [];

  @override
  void initState() {
    super.initState();
    cargarClasificaciones();
  }

  Future<void> cargarClasificaciones() async {
    final conectado = await verificarConexion();
    if (conectado) {
      debugPrint("Conectado a internet");
      await getClasificacionesDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando desde Hive...");
      await getClasificacionesDesdeHive();
    }
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  Future<void> getClasificacionesDesdeAPI() async {
    try {
      final clasificacionesService = ClasificacionesService();
      final List<dynamic> response =
          await clasificacionesService.listarClasificaciones();

      if (response.isNotEmpty) {
        final formateadas = formatModelClasificaciones(response);

        // Guardar en Hive
        final box = Hive.box('clasificacionesBox');
        await box.put('clasificaciones', formateadas);

        setState(() {
          dataClasificaciones = formateadas;
          loading = false;
        });
      } else {
        setState(() {
          dataClasificaciones = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las clasificaciones: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getClasificacionesDesdeHive() async {
    final box = Hive.box('clasificacionesBox');
    final List<dynamic>? guardadas = box.get('clasificaciones');

    if (guardadas != null) {
      final filtradas = guardadas
          .map<Map<String, dynamic>>(
              (item) => Map<String, dynamic>.from(item as Map))
          .where((item) => item['estado'] == "true")
          .toList();

      setState(() {
        dataClasificaciones = filtradas;
        loading = false;
      });
    } else {
      setState(() {
        dataClasificaciones = [];
        loading = false;
      });
    }
  }

  bool showModal = false;

  void openRegistroView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => Acciones(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: cargarClasificaciones,
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

  List<Map<String, dynamic>> formatModelClasificaciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'descripcion': item['descripcion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Clasificaciones"),
      body: loading
          ? Load()
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Clasificaciones",
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
                      onPressed: openRegistroView,
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblClasificaciones(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
                    },
                    clasificaciones: dataClasificaciones,
                    onCompleted: cargarClasificaciones,
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


