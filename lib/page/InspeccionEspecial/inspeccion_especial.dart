import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/inspeccion_anual.dart';
import '../../components/InspeccionEspecial/list_inspeccion_especial.dart';
import '../InspeccionAnual/inspeccion_anual.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class InspeccionEspecialPage extends StatefulWidget {
  @override
  _InspeccionEspecialPageState createState() => _InspeccionEspecialPageState();
}

class _InspeccionEspecialPageState extends State<InspeccionEspecialPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataInspecciones = [];

  @override
  void initState() {
    super.initState();
    getInspecciones();
  }

  Future<void> getInspecciones() async {
    try {
      final inspeccionAnualService = InspeccionAnualService();
      final List<dynamic> response = await inspeccionAnualService.listarInspeccionAnual();

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
      print("Error al obtener los clientes: $e");
      setState(() {
        loading = false; // En caso de error, desactivar el estado de carga
      });
    }
  }

  bool showModal = false; // Estado que maneja la visibilidad del modal

   // Función para abrir el modal de registro con el formulario de Acciones
  void openRegistroPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => InspeccionAnualPage(
              showModal: () {
                Navigator.pop(context); // Esto cierra el modal
              },
              onCompleted: getInspecciones,
              accion: "registrar",
              data: null)),
    ).then((_) {
      // Actualizar inspecciones al regresar de la página
    });
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
  }

  // Función para formatear los datos de las clientes
  List<Map<String, dynamic>> formatModelInspecciones(List<dynamic> data) {
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
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(currentPage: "Inspeccion Anual"), // Usa el menú lateral
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
                      "Inspeccion Anual",
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
                          openRegistroPage, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblInspeccionEspecial(
                    showModal: () {
                      Navigator.pop(
                          context); // Cierra el modal después de registrar
                    },
                    inspeccionAnual: dataInspecciones,
                    onCompleted:
                        getInspecciones, // Pasa la función para que se pueda llamar desde el componente
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
