import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../api/frecuencias.dart';
import '../../components/Frecuencias/list_frecuencias.dart';
import '../../components/Frecuencias/acciones.dart';
import '../../components/Load/load.dart';
import '../../components/Menu/menu_lateral.dart';
import '../../components/Header/header.dart';

class FrecuenciasPage extends StatefulWidget {
  @override
  _FrecuenciasPageState createState() => _FrecuenciasPageState();
}

class _FrecuenciasPageState extends State<FrecuenciasPage> {
  bool loading = true;
  List<Map<String, dynamic>> dataFrecuencias = [];

  @override
  void initState() {
    super.initState();
    getFrecuencias();
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

  bool showModal = false; // Estado que maneja la visibilidad del modal

  // Función para abrir el modal de registro con el formulario de Acciones
  void openRegistroModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Registrar periodo',
                  style: TextStyle(
                    fontSize: 23, // Tamaño más pequeño
                    fontWeight: FontWeight.bold, // Negrita
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context); // Cierra el diálogo
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                children: [
                  // Aquí agregamos un widget GestureDetector para que cuando el usuario toque fuera del formulario, el teclado se cierre.
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context)
                          .unfocus(); // Cierra el teclado al tocar fuera
                    },
                    child: Acciones(
                      showModal: () {
                        Navigator.pop(context); // Esto cierra el modal
                      },
                      onCompleted: getFrecuencias,
                      accion: "registrar",
                      data: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Cierra el modal
  void closeModal() {
    setState(() {
      showModal = false; // Cierra el modal
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(), // Usa el header con menú de usuario
      drawer: MenuLateral(currentPage: "Periodos"), // Usa el menú lateral
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
                      "Periodos",
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
                          openRegistroModal, // Abre el modal con el formulario de acciones
                      icon: Icon(FontAwesomeIcons.plus),
                      label: Text("Registrar"),
                    ),
                  ),
                ),
                Expanded(
                  child: TblFrecuencias(
                    showModal: () {
                      Navigator.pop(
                          context); // Cierra el modal después de registrar
                    },
                    frecuencias: dataFrecuencias,
                    onCompleted:
                        getFrecuencias, // Pasa la función para que se pueda llamar desde el componente
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
