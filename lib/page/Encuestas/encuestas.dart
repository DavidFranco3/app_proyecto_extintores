import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Encuestas/list_encuestas.dart';
import '../CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../components/Generales/premium_button.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';

class EncuestasPage extends StatefulWidget {
  const EncuestasPage({super.key});

  @override
  State<EncuestasPage> createState() => _EncuestasPageState();
}

class _EncuestasPageState extends State<EncuestasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataEncuestas = [];
  List<Map<String, dynamic>> filteredEncuestas = [];

  String? selectedFrecuencia;
  String? selectedClasificacion;

  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];

  TextEditingController nombreController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  TextEditingController ramaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    cargarTodo();
  }

  Future<void> cargarTodo() async {
    await getClasificaciones();
    await getFrecuencias();
    await getEncuestas();
  }

  Future<bool> verificarConexion() async {
    final tipoConexion = await Connectivity().checkConnectivity();
    if (tipoConexion.contains(ConnectivityResult.none)) return false;
    return await InternetConnection().hasInternetAccess;
  }

  // --- ENCUESTAS ---

  Future<void> getEncuestas() async {
    final conectado = await verificarConexion();

    if (conectado) {
      await getEncuestasDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando encuestas desde Hive...");
      await getEncuestasDesdeHive();
    }
  }

  Future<void> getEncuestasDesdeAPI() async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response =
          await encuestaInspeccionService.listarEncuestaInspeccion();

      if (response.isNotEmpty) {
        final encuestasFormateadas = formatModelEncuestas(response);

        // Guardar en Hive
        final box = Hive.box('encuestasBox');
        await box.put('encuestas', encuestasFormateadas);

        setState(() {
          dataEncuestas = encuestasFormateadas;
          filteredEncuestas = encuestasFormateadas;
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          filteredEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error al obtener encuestas desde API: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getEncuestasDesdeHive() async {
    try {
      final box = Hive.box('encuestasBox');
      final List<dynamic>? guardadas = box.get('encuestas');

      if (guardadas != null) {
        setState(() {
          dataEncuestas = guardadas
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .where((item) => item['estado'] == "true")
              .toList();
          filteredEncuestas = dataEncuestas;
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          filteredEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error leyendo encuestas desde Hive: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // --- CLASIFICACIONES ---

  Future<void> getClasificaciones() async {
    final conectado = await verificarConexion();
    if (conectado) {
      await getClasificacionesDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando clasificaciones desde Hive...");
      await getClasificacionesDesdeHive();
    }
  }

  Future<void> getClasificacionesDesdeAPI() async {
    try {
      final clasificacionesService = ClasificacionesService();
      final List<dynamic> response =
          await clasificacionesService.listarClasificaciones();

      if (response.isNotEmpty) {
        final clasificacionesFormateadas = formatModelClasificaciones(response);

        final box = Hive.box('clasificacionesBox');
        await box.put('clasificaciones', clasificacionesFormateadas);

        setState(() {
          dataClasificaciones = clasificacionesFormateadas;
        });
      } else {
        setState(() {
          dataClasificaciones = [];
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las clasificaciones desde API: $e");
      setState(() {
        dataClasificaciones = [];
      });
    }
  }

  Future<void> getClasificacionesDesdeHive() async {
    try {
      final box = Hive.box('clasificacionesBox');
      final List<dynamic>? guardadas = box.get('clasificaciones');

      if (guardadas != null) {
        setState(() {
          dataClasificaciones = guardadas
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .toList();
        });
      } else {
        setState(() {
          dataClasificaciones = [];
        });
      }
    } catch (e) {
      debugPrint("Error leyendo clasificaciones desde Hive: $e");
      setState(() {
        dataClasificaciones = [];
      });
    }
  }

  // --- FRECUENCIAS ---

  Future<void> getFrecuencias() async {
    final conectado = await verificarConexion();
    if (conectado) {
      await getFrecuenciasDesdeAPI();
    } else {
      debugPrint("Sin conexión, cargando frecuencias desde Hive...");
      await getFrecuenciasDesdeHive();
    }
  }

  Future<void> getFrecuenciasDesdeAPI() async {
    try {
      final frecuenciasService = FrecuenciasService();
      final List<dynamic> response =
          await frecuenciasService.listarFrecuencias();

      if (response.isNotEmpty) {
        final frecuenciasFormateadas = formatModelFrecuencias(response);

        final box = Hive.box('frecuenciasBox');
        await box.put('frecuencias', frecuenciasFormateadas);

        setState(() {
          dataFrecuencias = frecuenciasFormateadas;
        });
      } else {
        setState(() {
          dataFrecuencias = [];
        });
      }
    } catch (e) {
      debugPrint("Error al obtener las frecuencias desde API: $e");
      setState(() {
        dataFrecuencias = [];
      });
    }
  }

  Future<void> getFrecuenciasDesdeHive() async {
    try {
      final box = Hive.box('frecuenciasBox');
      final List<dynamic>? guardadas = box.get('frecuencias');

      if (guardadas != null) {
        setState(() {
          dataFrecuencias = guardadas
              .map<Map<String, dynamic>>(
                  (item) => Map<String, dynamic>.from(item))
              .toList();
        });
      } else {
        setState(() {
          dataFrecuencias = [];
        });
      }
    } catch (e) {
      debugPrint("Error leyendo frecuencias desde Hive: $e");
      setState(() {
        dataFrecuencias = [];
      });
    }
  }

  void filterEncuestas() {
    setState(() {
      filteredEncuestas = dataEncuestas.where((encuesta) {
        final frecuenciaMatch = selectedFrecuencia == null ||
            encuesta['frecuencia'] == selectedFrecuencia;
        final clasificacionMatch = selectedClasificacion == null ||
            encuesta['clasificacion'] == selectedClasificacion;
        return frecuenciaMatch && clasificacionMatch;
      }).toList();
    });
  }

  void clearFilters() {
    setState(() {
      selectedFrecuencia = null;
      selectedClasificacion = null;
      filteredEncuestas = dataEncuestas;
    });
  }

  void openRegistroPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CrearEncuestaPantalla1Screen(
          showModal: () {
            if (mounted) Navigator.pop(context);
          },
          onCompleted: getEncuestas,
          accion: "registrar",
          data: null,
          nombreController: nombreController,
          ramaController: ramaController,
          clasificacionController: clasificacionController,
        ),
      ),
    ).then((_) {
      getEncuestas();
    });
  }

  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    return data.map((item) {
      return {
        'id': item['_id'],
        'nombre': item['nombre'],
        'idFrecuencia': item['idFrecuencia'],
        'idClasificacion': item['idClasificacion'],
        'idRama': item['idRama'],
        'frecuencia': item['frecuencia']['nombre'],
        'clasificacion': item['clasificacion']['nombre'],
        'rama': item['rama']['nombre'],
        'preguntas': item['preguntas'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      };
    }).toList();
  }

  List<Map<String, dynamic>> formatModelFrecuencias(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
              'cantidadDias': item['cantidadDias'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  List<Map<String, dynamic>> formatModelClasificaciones(List<dynamic> data) {
    return data
        .map((item) => {
              'id': item['_id'],
              'nombre': item['nombre'],
              'descripcion': item['descripcion'],
              'estado': item['estado'],
              'createdAt': item['createdAt'],
              'updatedAt': item['updatedAt'],
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Crear actividad"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Crear actividad",
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
                      ),
                    ],
                  ),
                ),
                const Divider(indent: 20, endIndent: 20, height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      // Dropdown para Filtrar por Frecuencia
                      DropdownSearch<String>(
                        key: Key('frecuenciaDropdown'),
                        enabled: dataFrecuencias.isNotEmpty,
                        items: (filter, _) {
                          return dataFrecuencias
                              .where((f) => f['nombre']
                                  .toString()
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()))
                              .map((f) => f['nombre'].toString())
                              .toList();
                        },
                        selectedItem: selectedFrecuencia,
                        onChanged: dataFrecuencias.isEmpty
                            ? null
                            : (String? value) {
                                setState(() {
                                  selectedFrecuencia = value;
                                  filterEncuestas();
                                });
                              },
                        dropdownBuilder: (context, selectedItem) => Text(
                          selectedItem ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black),
                        ),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: "Frecuencia",
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),

// SizedBox para separación
                      SizedBox(height: 8),

// Dropdown para Filtrar por Clasificación
                      DropdownSearch<String>(
                        key: Key('clasificacionDropdown'),
                        enabled: dataClasificaciones.isNotEmpty,
                        items: (filter, _) {
                          return dataClasificaciones
                              .where((c) => c['nombre']
                                  .toString()
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()))
                              .map((c) => c['nombre'].toString())
                              .toList();
                        },
                        selectedItem: selectedClasificacion,
                        onChanged: dataClasificaciones.isEmpty
                            ? null
                            : (String? value) {
                                setState(() {
                                  selectedClasificacion = value;
                                  filterEncuestas();
                                });
                              },
                        dropdownBuilder: (context, selectedItem) => Text(
                          selectedItem ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              color: selectedItem == null
                                  ? Colors.grey
                                  : Colors.black),
                        ),
                        decoratorProps: DropDownDecoratorProps(
                          decoration: InputDecoration(
                            labelText: "Clasificación",
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                        ),
                        popupProps: PopupProps.menu(showSearchBox: true),
                      ),

                      SizedBox(height: 8),
                    ],
                  ),
                ),
                Expanded(
                  child: TblEncuestas(
                    showModal: () {
                      if (mounted) Navigator.pop(context);
                    },
                    encuestas: filteredEncuestas,
                    onCompleted: getEncuestas,
                  ),
                ),
              ],
            ),
    );
  }
}
