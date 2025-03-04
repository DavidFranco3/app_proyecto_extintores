import 'package:flutter/material.dart';
import '../Menu/menu_lateral.dart';
import '../Header/header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Load/load.dart';
import '../../api/inspecciones.dart';
import '../../api/inspecciones_proximas.dart';
import '../../page/Inspecciones/inspecciones.dart';
import '../../page/InspeccionesProximas/inspecciones_proximas.dart';
import '../../api/tokens.dart';
import '../../api/notificaciones.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> dataInspeccionesProximas = [];
  List<Map<String, dynamic>> dataInspeccionesProximas2 = [];
  List<Map<String, dynamic>> dataTokens = [];
  

  @override
  void initState() {
    super.initState();
    getInspecciones();
    getInspeccionesProximas();
    getTokens();
  }

  Future<void> getTokens() async {
    try {
      final tokensService = TokensService();
      final List<dynamic> response = await tokensService.listarTokens();

      // Filtrar los tokens donde tipo sea "administrador"
      final List<dynamic> filteredResponse = response.where((item) {
        return item['usuario']['tipo'] == 'inspector';
      }).toList();

      // Si la respuesta filtrada tiene datos, formateamos los datos y los asignamos al estado
      if (filteredResponse.isNotEmpty) {
        setState(() {
          dataTokens = formatModelTokens(filteredResponse);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataTokens = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener los tokens: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
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
      List<Map<String, dynamic>> formattedData =
          formatModelInspeccionesProximas(response);

      // Obtener la fecha actual
      DateTime fechaActual = DateTime.now();

      // Filtrar inspecciones con proximaInspeccion en 3 días o menos
      List<Map<String, dynamic>> inspeccionesFiltradas =
          formattedData.where((item) {
        DateTime proximaFecha = DateTime.parse(item['proximaInspeccion']);
        return proximaFecha.difference(fechaActual).inDays <= 3 &&
            proximaFecha.isAfter(fechaActual);
      }).toList();

      setState(() {
        dataInspeccionesProximas = formattedData; // Guardar todos los datos
        dataInspeccionesProximas2 =
            inspeccionesFiltradas; // Guardar solo las próximas en 3 días o menos
        loading = false; // Desactivar el estado de carga
      });
    } else {
      setState(() {
        dataInspeccionesProximas = []; // Lista vacía
        dataInspeccionesProximas2 = [];
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
  List<Map<String, dynamic>> formatModelTokens(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'idUsuario': item['idUsuario'],
        'token': item['token'],
        'usuario': item['usuario']['nombre'],
        'tipo': item['usuario']['tipo'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
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

  Timer? _notificationTimer; // Para evitar múltiples timers

// ✅ Enviar solicitud HTTP al backend de forma eficiente
Future<void> enviarNotificacionAlBackend() async {
  final notificacionesService = NotificacionesService();
  List<Future<void>> requests = [];

  for (var tokenData in dataTokens) {
    for (var inspeccionData in dataInspeccionesProximas2) {
      final formData = {
        "titulo": "Recordatorio de inspección",
        "token": tokenData["token"],
        "mensaje":
            "Se debe realizar la inspección de ${inspeccionData["cuestionario"]["nombre"]}"
      };

      // Agregar la solicitud a la lista para ejecutarlas en paralelo
      requests.add(notificacionesService.enviarNotificacion(formData));
    }
  }

  try {
    await Future.wait(requests); // Ejecutar todas las solicitudes en paralelo
  } catch (e) {
    print("Error al enviar notificaciones: $e");
  }
}

// ✅ Programar la llamada al backend cada 24 horas evitando múltiples timers
void scheduleDailyNotification() {
  if (_notificationTimer != null && _notificationTimer!.isActive) {
    return; // Evita que se cree otro timer si ya hay uno activo
  }

  _notificationTimer = Timer.periodic(Duration(hours: 24), (_) async {
    await enviarNotificacionAlBackend();
  });
}

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
                          color: const Color.fromARGB(3,4,6,255),
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
                          color: const Color.fromARGB(112,114,113,25),
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
