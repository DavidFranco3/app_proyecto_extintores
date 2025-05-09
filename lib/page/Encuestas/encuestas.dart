import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Encuestas/list_encuestas.dart';
import '../CrearEncuestaPantalla1/crear_encuesta_pantalla_1.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../api/frecuencias.dart';
import '../../api/clasificaciones.dart';

class EncuestasPage extends StatefulWidget {
  @override
  _EncuestasPageState createState() => _EncuestasPageState();
}

class _EncuestasPageState extends State<EncuestasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataEncuestas = [];
  List<Map<String, dynamic>> filteredEncuestas = [];

  TextEditingController nombreController = TextEditingController();
  TextEditingController clasificacionController = TextEditingController();
  TextEditingController ramaController = TextEditingController();

  String? selectedFrecuencia;
  String? selectedClasificacion;

  List<Map<String, dynamic>> dataFrecuencias = [];
  List<Map<String, dynamic>> dataClasificaciones = [];

  @override
  void initState() {
    super.initState();
    getEncuestas();
    getClasificaciones();
    getFrecuencias();
  }

  Future<void> getClasificaciones() async {
    try {
      final clasificacionesService = ClasificacionesService();
      final List<dynamic> response =
          await clasificacionesService.listarClasificaciones();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataClasificaciones = formatModelClasificaciones(response);
          loading = false; // Desactivar el estado de carga
        });
      } else {
        setState(() {
          dataClasificaciones = []; // Lista vacía
          loading = false; // Desactivar el estado de carga
        });
      }
    } catch (e) {
      print("Error al obtener las clasificaciones: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  Future<void> getFrecuencias() async {
    try {
      final frecuenciasService = FrecuenciasService();
      final List<dynamic> response =
          await frecuenciasService.listarFrecuencias();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataFrecuencias = formatModelFrecuencias(response);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          dataFrecuencias = [];
        });
      }
    } catch (e) {
      print("Error al obtener las frecuencias: $e");
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> getEncuestas() async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response =
          await encuestaInspeccionService.listarEncuestaInspeccion();

      if (response.isNotEmpty) {
        final encuestasFormateadas = formatModelEncuestas(response);
        setState(() {
          dataEncuestas = encuestasFormateadas;
          filteredEncuestas =
              encuestasFormateadas; // <- importante para mostrar
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
      print("Error al obtener las encuestas: $e");
      setState(() {
        loading = false;
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
            Navigator.pop(context);
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

  // Función para formatear los datos de las frecuencias
  List<Map<String, dynamic>> formatModelFrecuencias(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'nombre': item['nombre'],
        'cantidadDias': item['cantidadDias'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  // Función para formatear los datos de las clasificaciones
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
      drawer: MenuLateral(currentPage: "Crear actividad"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Crear actividad",
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

                // Filtros con selects
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedFrecuencia,
                        decoration: InputDecoration(
                          labelText: "Filtrar por frecuencia",
                          border: OutlineInputBorder(),
                        ),
                        items: dataFrecuencias.map((value) {
                          return DropdownMenuItem<String>(
                            value: value['nombre'],
                            child: Text(value['nombre']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedFrecuencia = value;
                          filterEncuestas();
                        },
                      ),
                      SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        value: selectedClasificacion,
                        decoration: InputDecoration(
                          labelText: "Filtrar por clasificación",
                          border: OutlineInputBorder(),
                        ),
                        items: dataClasificaciones.map((value) {
                          return DropdownMenuItem<String>(
                            value: value['nombre'],
                            child: Text(value['nombre']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedClasificacion = value;
                          filterEncuestas();
                        },
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),

                Expanded(
                  child: TblEncuestas(
                    showModal: () {
                      Navigator.pop(context);
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
