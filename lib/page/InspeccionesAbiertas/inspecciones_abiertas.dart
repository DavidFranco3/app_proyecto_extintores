import 'package:flutter/material.dart';
import '../../api/inspecciones.dart';
import '../../components/InspeccionesAbiertas/list_inspecciones_abiertas.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionesAbiertasPage extends StatefulWidget {

  @override
  _InspeccionesAbiertasPageState createState() => _InspeccionesAbiertasPageState();
}

class _InspeccionesAbiertasPageState extends State<InspeccionesAbiertasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];

  @override
  void initState() {
    super.initState();
    getInspecciones();
  }

  Future<void> getInspecciones() async {
    try {
      final inspeccionesService = InspeccionesService();
      final List<dynamic> response =
          await inspeccionesService.listarInspeccionesAbiertas();

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

  bool showModal = false; // Estado que maneja la visibilidad del modal

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
        'descripcion': item['descripcion'],
        'usuario': item['usuario']['nombre'],
        'cliente': item['cliente']['nombre'],
        'imagen_cliente': item['cliente']['imagen'],
        'firma_usuario': item['usuario']['firma'],
        'cuestionario': item['cuestionario']['nombre'],
        'usuarios': item['usuario'],
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
          currentPage: "Historial de inspecciones abiertas"), // Usa el menú lateral
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
                      "Inspecciones",
                      style: TextStyle(
                        fontSize: 24, // Tamaño grande
                        fontWeight: FontWeight.bold, // Negrita
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: TblInspecciones(
                    showModal: () {
                      Navigator.pop(context); // Esto cierra el modal
                    },
                    inspecciones: dataInspecciones,
                    onCompleted: getInspecciones,
                  ),
                ),
              ],
            ),
    );
  }
}
