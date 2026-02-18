import 'package:flutter/material.dart';
import '../../api/inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Generales/grafico.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../components/Generales/premium_inputs.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GraficaInspeccionesPage extends StatefulWidget {
  const GraficaInspeccionesPage({super.key});

  @override
  State<GraficaInspeccionesPage> createState() =>
      _GraficaInspeccionesPageState();
}

class _GraficaInspeccionesPageState extends State<GraficaInspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> dataEncuestas = [];
  String? selectedEncuestaId;

  late Box encuestasBox;
  late Box inspeccionesBox;

  @override
  void initState() {
    super.initState();
    encuestasBox = Hive.box('encuestasBox');
    inspeccionesBox = Hive.box('inspeccionesBox');
    cargarEncuestas();
  }

  /// Verifica si hay conexión a internet
  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  /// Cargar encuestas dependiendo de la conexión
  Future<void> cargarEncuestas() async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getEncuestasDesdeAPI();
      } else {
        await getEncuestasDesdeHive();
      }
    } catch (e) {
      debugPrint("Error al cargar encuestas: $e");
      setState(() {
        dataEncuestas = [];
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  /// Obtener encuestas desde la API y guardarlas en Hive
  Future<void> getEncuestasDesdeAPI() async {
    final encuestaService = EncuestaInspeccionService();
    final List<dynamic> response =
        await encuestaService.listarEncuestaInspeccion();

    if (response.isNotEmpty) {
      final formateadas = formatModelEncuestas(response)
          .where((item) => item['estado'] == "true")
          .toList();

      await encuestasBox.put('encuestas', formateadas);

      setState(() {
        dataEncuestas = formateadas;
      });
    }
  }

  /// Obtener encuestas desde Hive
  Future<void> getEncuestasDesdeHive() async {
    final List<dynamic>? guardadas = encuestasBox.get('encuestas');

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

  /// Cargar inspecciones según la conexión
  Future<void> cargarInspecciones(String encuestaId) async {
    try {
      final conectado = await verificarConexion();
      if (conectado) {
        await getInspeccionesDesdeAPI(encuestaId);
      } else {
        await getInspeccionesDesdeHive(encuestaId);
      }
    } catch (e) {
      debugPrint("Error al cargar inspecciones: $e");
      setState(() {
        dataInspecciones = [];
      });
    }
  }

  /// Obtener inspecciones desde la API y guardarlas en Hive
  Future<void> getInspeccionesDesdeAPI(String encuestaId) async {
    final inspeccionesService = InspeccionesService();
    final List<dynamic> response =
        await inspeccionesService.listarInspeccionesResultados(encuestaId);

    if (response.isNotEmpty) {
      final formateadas = formatModelInspecciones(response);

      // Guardar en Hive usando el ID como clave
      await inspeccionesBox.put(encuestaId, formateadas);

      setState(() {
        dataInspecciones = formateadas;
      });
    }
  }

  /// Obtener inspecciones desde Hive
  Future<void> getInspeccionesDesdeHive(String encuestaId) async {
    final List<dynamic>? guardadas = inspeccionesBox.get(encuestaId);

    if (guardadas != null) {
      final locales = List<Map<String, dynamic>>.from(
        guardadas.map((e) => Map<String, dynamic>.from(e)),
      );

      setState(() {
        dataInspecciones = locales;
      });
    }
  }

  /// Formatea datos de inspecciones
  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'pregunta': item['pregunta'],
        'si': item['si'],
        'no': item['no'],
      };
    }).toList();
  }

  /// Formatea datos de encuestas
  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    return data.map<Map<String, dynamic>>((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'idFrecuencia': item['idFrecuencia'],
        'idClasificacion': item['idClasificacion'],
        'frecuencia': item['frecuencia']['nombre'],
        'clasificacion': item['clasificacion']['nombre'],
        'preguntas': item['preguntas'],
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
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: PremiumSectionTitle(title: "Gráfico de actividades"),
                  ),
                  const SizedBox(height: 15),

                  // Dropdown para seleccionar la encuesta
                  PremiumCardField(
                    child: DropdownButtonFormField<String>(
                      decoration: PremiumInputs.decoration(
                        labelText: "Seleccionar Encuesta",
                        prefixIcon: FontAwesomeIcons.clipboardList,
                      ),
                      initialValue: selectedEncuestaId,
                      items:
                          dataEncuestas.map<DropdownMenuItem<String>>((item) {
                        return DropdownMenuItem<String>(
                          value: item['id'].toString(),
                          child: Text(
                            "${item['nombre']} - ${item['frecuencia']}",
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: loading
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedEncuestaId = newValue;
                                });
                                cargarInspecciones(newValue);
                              }
                            },
                      isExpanded: true,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: PremiumCardField(
                      padding: const EdgeInsets.all(16),
                      child: dataInspecciones.isNotEmpty
                          ? GraficaBarras(
                              dataInspecciones: dataInspecciones,
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(FontAwesomeIcons.chartBar,
                                      size: 50, color: Colors.grey),
                                  SizedBox(height: 10),
                                  Text("No hay datos para mostrar",
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
