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
import 'package:dropdown_search/dropdown_search.dart';

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
                    child: DropdownSearch<Map<String, dynamic>>(
                      items: (filter, _) => dataEncuestas
                          .where((encuesta) =>
                              encuesta['nombre']
                                  .toString()
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()) ||
                              encuesta['frecuencia']
                                  .toString()
                                  .toLowerCase()
                                  .contains(filter.toLowerCase()))
                          .toList(),
                      itemAsString: (item) =>
                          "${item['nombre']} - ${item['frecuencia']}",
                      compareFn: (item1, item2) => item1['id'] == item2['id'],
                      selectedItem: selectedEncuestaId != null
                          ? dataEncuestas.firstWhere(
                              (element) =>
                                  element['id'].toString() ==
                                  selectedEncuestaId,
                              orElse: () => {})
                          : null,
                      onChanged: loading
                          ? null
                          : (nuevoItem) {
                              if (nuevoItem != null) {
                                setState(() {
                                  selectedEncuestaId =
                                      nuevoItem['id'].toString();
                                });
                                cargarInspecciones(nuevoItem['id'].toString());
                              }
                            },
                      dropdownBuilder: (context, selectedItem) {
                        return Text(
                          selectedItem == null
                              ? ""
                              : "${selectedItem['nombre']} - ${selectedItem['frecuencia']}",
                          style: TextStyle(
                            fontSize: 14,
                            color: selectedItem == null
                                ? Colors.grey
                                : Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                      decoratorProps: DropDownDecoratorProps(
                        decoration: PremiumInputs.decoration(
                          labelText: "Seleccionar Encuesta",
                          prefixIcon: FontAwesomeIcons.clipboardList,
                        ),
                      ),
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        fit: FlexFit.loose,
                        itemBuilder:
                            (context, item, isSelected, isItemDisabled) =>
                                Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Text(
                            "${item['nombre']} - ${item['frecuencia']}",
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
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
