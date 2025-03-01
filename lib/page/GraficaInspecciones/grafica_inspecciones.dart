import 'package:flutter/material.dart';
import '../../api/inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../../api/encuesta_inspeccion.dart';
import '../../components/Generales/grafico.dart';

class GraficaInspeccionesPage extends StatefulWidget {
  @override
  _GraficaInspeccionesPageState createState() =>
      _GraficaInspeccionesPageState();
}

class _GraficaInspeccionesPageState extends State<GraficaInspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];
  List<Map<String, dynamic>> dataEncuestas = [];
  String?
      selectedEncuestaId; // Variable para almacenar el ID de la encuesta seleccionada

  @override
  void initState() {
    super.initState();
    getEncuestas(); // Obtenemos las encuestas al iniciar
  }

  // Obtener las encuestas disponibles
  Future<void> getEncuestas() async {
    try {
      final encuestaInspeccionService = EncuestaInspeccionService();
      final List<dynamic> response =
          await encuestaInspeccionService.listarEncuestaInspeccion();

      if (response.isNotEmpty) {
        setState(() {
          dataEncuestas = formatModelEncuestas(response);
          loading = false;
        });
      } else {
        setState(() {
          dataEncuestas = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las encuestas: $e");
      loading = false;
    }
  }

  // Obtener las inspecciones filtradas por encuesta
  Future<void> getInspecciones(String encuestaId) async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspeccionesResultados(encuestaId);

      if (response.isNotEmpty) {
        setState(() {
          // Procesamos las inspecciones y las asignamos
          dataInspecciones = formatModelInspecciones(response);
          loading = false;
        });
      } else {
        setState(() {
          dataInspecciones = [];
          loading = false;
        });
      }
    } catch (e) {
      print("Error al obtener las inspecciones: $e");
      setState(() {
        loading = false;
      });
    }
  }

  // Función para formatear los datos de las inspecciones
  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'pregunta': item['pregunta'],
        'si': item['si'],
        'no': item['no'],
      });
    }
    return dataTemp;
  }

  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
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
      });
    }
    return dataTemp;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(),
      drawer: MenuLateral(currentPage: "Gráfico de Inspecciones"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Gráfico de Inspecciones",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Dropdown para seleccionar la encuesta
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Seleccionar Encuesta",
                      border: OutlineInputBorder(),
                    ),
                    value: selectedEncuestaId,
                    isExpanded: true,
                    items: dataEncuestas
                        .map((encuesta) => DropdownMenuItem<String>(
                              value: encuesta['id'],
                              child: Text(encuesta['nombre'] + " - " + encuesta['frecuencia']),
                            ))
                        .toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedEncuestaId = newValue;
                      });
                      if (newValue != null) {
                        getInspecciones(
                            newValue); // Cargar las inspecciones para el ID de encuesta seleccionado
                      }
                    },
                  ),
                ),
                Expanded(
                  child: GraficaBarras(
                    dataInspecciones: dataInspecciones,
                    // Puedes pasar los datos filtrados si es necesario
                  ),
                ),
              ],
            ),
    );
  }
}
