import 'package:flutter/material.dart';
import '../../api/inspecciones.dart';
import '../../components/Inspecciones/list_inspecciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';
import '../InspeccionesPantalla2/inspecciones_pantalla_2.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class InspeccionesPage extends StatefulWidget {
  final VoidCallback showModal;
  final dynamic data;
  final dynamic data2;

  InspeccionesPage(
      {required this.showModal, required this.data, required this.data2});
  @override
  _InspeccionesPageState createState() => _InspeccionesPageState();
}

class _InspeccionesPageState extends State<InspeccionesPage> {
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
          await inspeccionesService.listarInspeccionesDatos(widget.data["id"]);

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
        'imagenesCloudinary': item['imagenesCloudinary'],
        'comentarios': item['comentarios'],
        'descripcion': item['descripcion'],
        'usuario': item['usuario']['nombre'],
        'cliente': item['cliente']['nombre'],
        'imagen_cliente': item['cliente']['imagen'],
        'imagen_cliente_cloudinary': item['cliente']['imagenCloudinary'],
        'firma_usuario': item['usuario']['firma'],
        'firma_usuario_cloudinary': item['usuario']['firmaCloudinary'],
        'cuestionario': item['cuestionario']['nombre'],
        'usuarios': item['usuario'],
        'estado': item['estado'],
        'createdAt': item['createdAt'],
        'updatedAt': item['updatedAt'],
      });
    }
    return dataTemp;
  }

  // Función para abrir el modal de registro con el formulario de Acciones
  void returnPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InspeccionesPantalla2Page(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              data: widget.data2)),
    ).then((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(
          currentPage: "Historial de inspecciones"), // Usa el menú lateral
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: ElevatedButton.icon(
                      onPressed:
                          returnPage, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.arrowLeft),
                      label: Text("Regresar"),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      "Cliente: ${widget.data["cliente"]}",
                      style: TextStyle(
                        fontSize: 18,
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
