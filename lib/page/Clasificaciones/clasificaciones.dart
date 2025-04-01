import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/clasificaciones.dart';
import '../../components/Clasificaciones/list_clasificaciones.dart';
import '../../components/Clasificaciones/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class ClasificacionesPage extends StatefulWidget {
  @override
  _ClasificacionesPageState createState() => _ClasificacionesPageState();
}

class _ClasificacionesPageState extends State<ClasificacionesPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataClasificaciones = [];

  @override
  void initState() {
    super.initState();
    getClasificaciones();
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

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para redirigir a la vista de registro de Acciones
  void openRegistroView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => Acciones(
          showModal: () {
            Navigator.pop(context); // Cierra la vista al completar
          },
          onCompleted: getClasificaciones,
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
      appBar: Header(), // Usa el header con menú de usuario
      drawer:
          MenuLateral(currentPage: "Clasificaciones"), // Usa el menú lateral
      body: loading
          ? Load() // Muestra el widget de carga mientras se obtienen los datos
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Centra el encabezado
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Clasificaciones",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
                // Centra el botón de registrar
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          openRegistroView, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblClasificaciones(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    clasificaciones: dataClasificaciones,
                    onCompleted: getClasificaciones,
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
