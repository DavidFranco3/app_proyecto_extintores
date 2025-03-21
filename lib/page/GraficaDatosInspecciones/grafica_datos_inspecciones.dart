import 'package:flutter/material.dart';
import 'package:prueba/components/Generales/grafico_lineas.dart';
import '../../api/inspeccion_anual.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class GraficaDatosInspeccionesPage extends StatefulWidget {
  final String idInspeccion;

  GraficaDatosInspeccionesPage(
      {required this.idInspeccion});

  @override
  _GraficaDatosInspeccionesPageState createState() =>
      _GraficaDatosInspeccionesPageState();
}

class _GraficaDatosInspeccionesPageState extends State<GraficaDatosInspeccionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataEncuestas = [];

  @override
  void initState() {
    super.initState();
    getEncuestas(); // Obtenemos las encuestas al iniciar
  }

  // Obtener las encuestas disponibles
  Future<void> getEncuestas() async {
    try {
      final inspeccionAnualService = InspeccionAnualService();
      final List<dynamic> response =
          await inspeccionAnualService.listarInspeccionAnualId(widget.idInspeccion);
          print(response);

      if (response.isNotEmpty) {
        setState(() {
          dataEncuestas = formatModelEncuestas(response);
          print("aca estoy");
          print(dataEncuestas);
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

  List<Map<String, dynamic>> formatModelEncuestas(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'titulo': item['titulo'],
        'idCliente': item['idCliente'],
        'datos': item['datos'],
        'cliente': item['cliente']['nombre'],
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
      drawer: MenuLateral(currentPage: "Gráfico de Datos"),
      body: loading
          ? Load()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Gráfico de Datos",
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
                ),
                Expanded(
                  child: GraficaLineas(
                    encuestaAbierta: dataEncuestas,
                    // Puedes pasar los datos filtrados si es necesario
                  ),
                ),
              ],
            ),
    );
  }
}
