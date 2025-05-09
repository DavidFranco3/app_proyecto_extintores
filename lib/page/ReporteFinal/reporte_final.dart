import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:prueba/page/RegistrarReporte/registrar_reporte.dart';
import '../../api/reporte_final.dart';
import '../../components/ReporteFinal/list_reporte_final.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class ReporteFinalPage extends StatefulWidget {
  @override
  _ReporteFinalPageState createState() => _ReporteFinalPageState();
}

class _ReporteFinalPageState extends State<ReporteFinalPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataReporteFinal = [];

  @override
  void initState() {
    super.initState();
    getReporteFinal();
  }

  Future<void> getReporteFinal() async {
    try {
      final reporteFinalService = ReporteFinalService();
      final List<dynamic> response =
          await reporteFinalService.listarReporteFinal();

      // Si la respuesta tiene datos, formateamos los datos y los asignamos al estado
      if (response.isNotEmpty) {
        setState(() {
          dataReporteFinal = formatModelReporteFinal(response);
          loading = false;
        });
      } else {
        setState(() {
          loading = false;
          dataReporteFinal = [];
        });
      }
    } catch (e) {
      print("Error al obtener los reportes finales: $e");
      setState(() {
        loading = false;
      });
    }
  }

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para abrir el modal de registro con el formulario de Acciones
  void openRegistroModal() {
    // Navegar a la página de registro en lugar de mostrar un modal
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistrarReporteScreen(
          showModal: () {
            Navigator.pop(context); // Esto cierra la pantalla
          },
          onCompleted: getReporteFinal,
          accion: "registrar",
          data: null,
        ),
      ),
    );
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
  }

  // Función para formatear los datos de las reportes finales
  List<Map<String, dynamic>> formatModelReporteFinal(List<dynamic> data) {
    List<Map<String, dynamic>> dataTemp = [];
    for (var item in data) {
      dataTemp.add({
        'id': item['_id'],
        'descripcion': item['descripcion'],
        'imagenes': item['imagenes'],
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
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(
        currentPage: "Reporte de Actividades y pruebas",
      ), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Reporte de Actividades y pruebas",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          openRegistroModal, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblReporteFinal(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    reporteFinal: dataReporteFinal,
                    onCompleted: getReporteFinal,
                  ),
                ),
              ],
            ),
      // Modal: Se muestra solo si `showModal` es true
      floatingActionButton: showModal
          ? FloatingActionButton(
              onPressed: closeModal, // Cierra el modal
              child: Icon(Icons.close),
            )
          : null,
    );
  }
}
