import 'package:flutter/material.dart';
import '../Menu/menu_lateral.dart';
import '../Header/header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Load/load.dart';
import '../../api/inspecciones.dart';
import '../../api/inspecciones_proximas.dart';
import '../../page/Inspecciones/inspecciones.dart';
import '../../page/InspeccionesProximas/inspecciones_proximas.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> dataInspeccionesProximas = [];

  @override
  void initState() {
    super.initState();
    getInspecciones();
    getInspeccionesProximas();
  }

  Future<void> getInspecciones() async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspecciones();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataInspecciones = formatModelInspecciones(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataInspecciones = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las inspecciones: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  Future<void> getInspeccionesProximas() async {
    try {
      final inspeccionesProximasService = InspeccionesProximasService();
      final List<dynamic> response =
          await inspeccionesProximasService.listarInspeccionesProximas();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataInspeccionesProximas = formatModelInspeccionesProximas(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataInspeccionesProximas = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las inspeccionesProximas: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  // Función para formatear los datos de las inspecciones
  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'idCliente': item['idCliente'],
        'idEncuesta': item['idEncuesta'],
        'encuesta': item['encuesta'],
        'imagenes': item['imagenes'],
        'comentarios': item['comentarios'],
        'usuario': item['usuario']['nombre'],
        'cliente': item['cliente']['nombre'],
        'cuestionario': item['cuestionario']['nombre'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  // Función para formatear los datos de las inspeccionesProximas
  List<Map<String, dynamic>> formatModelInspeccionesProximas(
      List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idFrecuencia': item['idFrecuencia'],
        'idEncuesta': item['idEncuesta'],
        'cuestionario': item['cuestionario']['nombre'],
        'frecuencia': item['frecuencia']['nombre'],
        'proximaInspeccion': item['nuevaInspeccion'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  bool mostrarMasHechas = false;
  bool mostrarMasProximas = false;
  bool mostrarMasFueraTiempo = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Inicio"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Center(
                    child: Text(
                      "Inicio",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView(
                      children: [
                        // 🟢 Inspecciones Hechas
                        Card(
                          color: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  "Inspecciones Hechas",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  dataInspecciones.length.toString(),
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 12),
                                Icon(FontAwesomeIcons.clipboardCheck,
                                    size: 40, color: Colors.white),
                                SizedBox(height: 12),

                                // Botón Ver más / Ver menos que redirige a otra página
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InspeccionesPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Ver más",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // 🔹 Inspecciones Próximas
                        Card(
                          color: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  "Inspecciones Próximas",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  dataInspeccionesProximas.length.toString(),
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 12),
                                Icon(FontAwesomeIcons.calendarCheck,
                                    size: 40, color: Colors.white),
                                SizedBox(height: 12),

                                // Botón Ver más / Ver menos que redirige a otra página
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            InspeccionesProximasPage(),
                                      ),
                                    );
                                  },
                                  child: Text(
                                    "Ver más",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // 🔴 Inspecciones Fuera de Tiempo
                        Card(
                          color: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  "Inspecciones Fuera de Tiempo",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "0",
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                SizedBox(height: 12),
                                Icon(FontAwesomeIcons.exclamationTriangle,
                                    size: 40, color: Colors.white),
                                SizedBox(height: 12),

                                // Información extra
                                if (mostrarMasFueraTiempo)
                                  Column(
                                    children: [
                                      Text(
                                        "Detalles sobre inspecciones fuera de tiempo...",
                                        style: TextStyle(
                                            fontSize: 16, color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 8),
                                    ],
                                  ),

                                // Botón Ver más / Ver menos
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      mostrarMasFueraTiempo =
                                          !mostrarMasFueraTiempo;
                                    });
                                  },
                                  child: Text(
                                    mostrarMasFueraTiempo
                                        ? "Ver menos"
                                        : "Ver más",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
